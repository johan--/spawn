defmodule Statestores.Adapters.LookupBehaviour do
  @moduledoc """
  `LookupBehaviour` defines how system get clustered actors info.
  """
  @type actor_host :: String.t()

  @callback get(any()) :: {:ok, any()} | {:error, any()}

  @callback get_by_key(any()) :: {:ok, any()} | {:error, any()}

  @callback get_all_by_node(any()) :: {:ok, any()} | {:error, any()}

  @callback set(any()) :: {:error, any()} | {:ok, any()}

  @callback delete(any()) :: {:error, any()} | {:ok, any()}

  @callback delete_all_by_node(actor_host()) :: {:error, any()} | {:ok, any()}

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.LookupBehaviour
      import Statestores.Util, only: [init_config: 1]

      @behaviour Statestores.Adapters.LookupBehaviour

      def init(_type, config), do: init_config(config)
    end
  end
end
