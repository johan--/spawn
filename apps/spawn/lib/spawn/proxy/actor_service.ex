defmodule Spawn.Proxy.ActorService do
  use GRPC.Server, service: Eigr.Functions.Protocol.ActorService.Service
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorEntity, ActorSystem, Registry}
  alias Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor, as: ActorEntitySupervisor

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorSystemRequest,
    ActorSystemResponse,
    InvocationRequest,
    InvocationResponse,
    RegistrationRequest,
    RegistrationResponse,
    ServiceInfo
  }

  alias Spawn.Proxy.NodeManager
  alias Spawn.Proxy.NodeManager.Supervisor, as: NodeManagerSupervisor

  @spec spawn(ActorSystemRequest.t(), GRPC.Server.Stream.t()) :: ActorSystemResponse.t()
  def spawn(messages, stream) do
    messages
    |> Stream.each(fn %ActorSystemRequest{message: message} -> handle(message, stream) end)
    |> Stream.run()
  end

  defp handle(
         {:registration_request,
          %RegistrationRequest{
            service_info: %ServiceInfo{} = service_info,
            actor_system:
              %ActorSystem{name: name, registry: %Registry{actors: actors} = registry} =
                actor_system
          } = registration} = _message,
         stream
       ) do
    Logger.debug("Registration request received: #{inspect(registration)}")

    case NodeManagerSupervisor.create_connection_manager(%{
           actor_system: name,
           source_stream: stream
         }) do
      {:ok, pid} ->
        create_actors(actors)

      reason ->
        Logger.error("Failed to spawn actor system: #{inspect(reason)}")
    end
  end

  defp handle(
         {:invocation_request,
          %InvocationRequest{
            actor:
              %Actor{name: actor_name, actor_system: %ActorSystem{name: system_name}} = actor,
            async: invocation_type
          } = request} = _message,
         stream
       ) do
    Logger.debug("Invocation request received: #{inspect(request)}")
    invoke(invocation_type, actor, request, stream)
  end

  defp handle(
         {:actor_invocation_response, %ActorInvocation{} = actor_invocation_response} = _message,
         stream
       ) do
    Logger.debug("Actor invocation response received: #{inspect(actor_invocation_response)}")
  end

  defp create_actors(actors) do
    Enum.each(actors, fn {actor_name, actor} ->
      Logger.debug(
        "Registering #{actor_name}: #{inspect(actor)} on Node: #{inspect(Node.self())}"
      )

      case ActorEntitySupervisor.lookup_or_create_actor(actor) do
        {:ok, pid} ->
          Logger.debug("Registered Actor #{actor_name} with pid: #{pid}")

        _ ->
          Logger.debug("Failed to register Actor #{actor_name}")
      end
    end)
  end

  defp invoke(
         false,
         %Actor{name: actor_name, actor_system: %ActorSystem{name: system_name}} = actor,
         request,
         stream
       ) do
    # TODO: invoke try_reactivate on some Node with actor registered
    case NodeManager.try_reactivate(system_name, actor) do
      {:ok, pid} ->
        ActorEntity.invoke_sync(actor_name, request)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp invoke(
         true,
         %Actor{name: actor_name, actor_system: %ActorSystem{name: system_name}} = actor,
         request,
         stream
       ) do
    case NodeManager.try_reactivate(system_name, actor) do
      {:ok, pid} ->
        ActorEntity.invoke_sync(actor_name, request)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
