defmodule Slax.ProjectCommand do
  @behaviour Slax.Command

  @spec new(map, list(binary)) :: binary()
  def new(%{github_access_token: github_access_token}, [name]) do
    name
    |> Slax.Commands.NewProject.new_project(String.trim(github_access_token))
    |> Slax.Commands.NewProject.format_results()
  end
end
