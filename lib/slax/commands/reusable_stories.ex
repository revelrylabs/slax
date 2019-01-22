defmodule Slax.Commands.ReuseableStories do
  @moduledoc """
  Adds reusable stories to a given repo
  """
  alias Slax.Commands.GithubCommands

  @doc """
  Adds reusable stories to the given repo
  """
  @spec reuseable_stories(binary, binary) :: map
  def reuseable_stories(name, github_access_token) do
    org_name = Application.get_env(:slax, Slax.Github)[:org_name]
    story_repo = Application.get_env(:slax, :reusable_stories)[:repo]
    story_paths = Application.get_env(:slax, :reusable_stories)[:paths]

    reuseable_stories(org_name, name, github_access_token, story_repo, story_paths)
  end

  @doc """
  Adds reusable stories to the given repo

  See reuseable_stories/2
  """
  @spec reuseable_stories(binary, binary, binary, binary, keyword(binary)) :: map
  def reuseable_stories(org_name, name, github_access_token, story_repo, story_paths) do
    %{errors: %{}, success: %{}}
    |> GithubCommands.parse_project_name(name)
    |> GithubCommands.create_reusable_stories(
      github_access_token,
      org_name,
      story_repo,
      story_paths
    )
  end
end
