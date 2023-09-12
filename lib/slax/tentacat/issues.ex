defmodule Slax.Tentacat.Issues do
  def find(client, org, repo, issue) do
    tentacat().find(client, org, repo, issue)
  end

  defp tentacat() do
    Application.get_env(:slax, :tentacat_issues)
  end
end
