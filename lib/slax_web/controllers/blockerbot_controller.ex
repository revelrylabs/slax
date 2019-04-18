defmodule SlaxWeb.BlockerbotController do
  use SlaxWeb, :controller

  alias Slax.{ProjectRepos, Github}


def start(conn, _params) do
  repos = ProjectRepos.get_repos()
  repos
    |> Enum.map(fn repo ->
    Github.fetch_issues(repo)
    end)
  text(conn, "ok")
end

end
