defmodule Slax.Commands.GithubCommands.Behaviour do
  @moduledoc false
  @typep results :: map()
  @typep github_access_token :: String.t()
  @typep org_name :: String.t()
  @typep story_repo :: String.t()
  @typep project_name :: String.t()
  @typep story_paths :: [String.t()]

  @callback create_reusable_stories(
              results,
              github_access_token,
              org_name,
              story_repo,
              story_paths
            ) :: results

  @callback parse_project_name(results, project_name) :: results
end
