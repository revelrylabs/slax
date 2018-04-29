defmodule Slax.CommandRouter do
  @doc """
  Routes command to the appropriate command module

  Finds the proper module based on the first arg given.

  It then routes to a function on that module based on
  the second arg

  ```elixir
  # Calling the function below as:
  Slax.CommandRouter.parse(context, ["project", "new", "name"])

  # Would call:
  ProjectCommand.new(context, ["name"])

  # If a function the above function was not defined, it would instead call
  ProjectCommand.help(context, ["project", "new", "name"])
  """
  @spec route(any, list()) :: {:ok, any} | {:error, :nofile}
  def route(context, [group, command | rest]) do
    group_module = create_module_name(group)
    command = String.to_atom(command)

    if Code.ensure_loaded?(group_module) do
      result =
        if function_exported?(group_module, command, 2) do
          apply(group_module, command, [context, rest])
        else
          apply(group_module, :help, [context, [command | rest]])
        end

      {:ok, result}
    else
      {:error, :nofile}
    end
  end

  defp create_module_name(group) do
    group_module =
      "#{group}_command"
      |> Macro.camelize()
      |> String.to_atom()

    Module.concat(Slax, group_module)
  end
end
