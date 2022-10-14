defmodule SpawnSdk.Defact do
  @moduledoc """
  Define actions like a Elixir functions

  ### Internal :defact_exports metadata saved as
  [
    {action_name, %{timer: 10_000}},
    {action_name2, %{timer: nil}}
  ]
  """

  defmacro __using__(_args) do
    quote do
      import SpawnSdk.Defact

      Module.register_attribute(__MODULE__, :defact_exports, accumulate: true)

      @set_timer nil
    end
  end

  defmacro defact(call, do: block) do
    define_defact(:def, call, block, __CALLER__)
  end

  defp define_defact(kind, call, block, env) do
    {name, args} = decompose_call!(kind, call, env)
    [first_arg, last_arg] = args

    quote do
      Module.put_attribute(
        __MODULE__,
        :defact_exports,
        Macro.escape({unquote(name), %{timer: @set_timer}})
      )

      def handle_command({unquote(name), unquote(first_arg)}, unquote(last_arg)) do
        unquote(block)
      end
    end
  end

  defp decompose_call!(kind, {:when, _, [call, _guards]}, env),
    do: decompose_call!(kind, call, env)

  defp decompose_call!(_kind, {{:unquote, _, [name]}, _, args}, _env) do
    {name, args}
  end

  defp decompose_call!(kind, call, env) do
    case Macro.decompose_call(call) do
      {name, args} ->
        {name, args}

      :error ->
        compile_error!(
          env,
          "first argument of #{kind}n must be a call, got: #{Macro.to_string(call)}"
        )
    end
  end

  defp compile_error!(env, description) do
    raise CompileError, line: env.line, file: env.file, description: description
  end
end
