defmodule Slax.Tentacat.Prs do
  @moduledoc false
  def find(client, org, repo, issue) do
    tentacat().find(client, org, repo, issue)
  end

  defp tentacat() do
    Application.get_env(:slax, :tentacat_prs)
  end
end
