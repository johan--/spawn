Mimic.copy(Actors.Node.Client)

Spawn.InitializerHelper.setup()

ExUnit.start()
Faker.start()

node = Spawn.NodeHelper.spawn_peer("spawn_actors_node", applications: [:spawn])

case Spawn.NodeHelper.rpc(node, Spawn.InitializerHelper, :setup, []) do
  {:error, error} ->
    IO.puts(
      "** Failed to start sidecar in the peer node, check if applications are correctly started"
    )

    throw(error)

  {:ok, pid} ->
    IO.puts("** Sidecar successfully started in peer node in pid=#{inspect(pid)}")
end

IO.puts("Nodes connected: #{inspect(Node.list())}")
