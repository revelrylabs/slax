defmodule Slax.Commands.NewProject do
  @moduledoc """
  Automates creation of a new project
  """
  alias Slax.{Github, Slack}

  @doc """
  Automates creating a new project.
  This includes:
  * Add private GitHub repo
  * Create Slack channel
  * Add general issues to GitHub Repo
  * Adds Lintron webhook to GitHub Repo
  * Adds Board Checker to GitHub Repo
  * Adds Teams to GitHub Repo

  If some steps fail, others will still try to complete, unless they depend on previous steps
  """
  @spec new_project(binary, binary) :: map
  def new_project(name, github_access_token) do
    org_name = Application.get_env(:slax, Slax.Github)[:org_name]
    org_teams = Application.get_env(:slax, Slax.Github)[:org_teams]
    story_repo = Application.get_env(:slax, :reusable_stories)[:repo]
    story_paths = Application.get_env(:slax, :reusable_stories)[:paths]

    new_project(org_name, name, github_access_token, story_repo, story_paths, org_teams)
  end

  @doc """
  Automates creating a new project.

  See new_project/2
  """
  @spec new_project(binary, binary, binary, binary, keyword(binary), binary) :: map
  def new_project(org_name, name, github_access_token, story_repo, story_paths, org_teams) do
    %{errors: %{}, success: %{}}
    |> github_commands().parse_project_name(name)
    |> create_github_repo(github_access_token, org_name)
    |> create_slack_channel
    |> github_commands().create_reusable_stories(
      github_access_token,
      org_name,
      story_repo,
      story_paths
    )
    |> add_org_teams(github_access_token, org_name, org_teams)
    |> add_webhook(
      lintron_params(name, github_access_token, org_name),
      :lintron,
      "Lintron Created"
    )
    |> add_webhook(
      board_checker_params(name, github_access_token, org_name),
      :board_checker,
      "Board Checker Created"
    )
  end

  defp github_commands(), do: Application.get_env(:slax, :github_commands)

  defp create_github_repo(%{project_name: project_name} = results, github_access_token, org_name) do
    case Github.find_or_create_repo(%{
           name: project_name,
           access_token: github_access_token,
           org_name: org_name
         }) do
      {:ok, repo_url} ->
        Map.put(results, :github_repo, repo_url)
        |> Map.update(:success, %{}, fn x ->
          Map.put(x, :github_repo, "Github Repo Found or Created: <#{repo_url}>")
        end)

      {:error, message} ->
        Map.update(results, :errors, %{}, fn x -> Map.put(x, :github_repo, message) end)
    end
  end

  defp create_github_repo(results, _, _) do
    results
  end

  defp create_slack_channel(%{project_name: project_name} = results) do
    case Slack.create_channel(String.downcase(project_name)) do
      {:ok, channel} ->
        channel_name = channel["name"]
        channel_id = channel["id"]
        formatted_channel_name = "<##{channel_id}|#{channel_name}>"

        Map.put(results, :slack_channel, channel_name)
        |> Map.update(:success, %{}, fn x ->
          Map.put(x, :slack_channel, "Channel Created: #{formatted_channel_name}")
        end)

      {:error, message} ->
        Map.update(results, :errors, %{}, fn x -> Map.put(x, :slack_channel, message) end)
    end
  end

  defp create_slack_channel(results) do
    results
  end

  defp add_org_teams(
         %{project_name: project_name, github_repo: _} = results,
         github_access_token,
         org_name,
         org_teams
       ) do
    repo = "#{org_name}/#{project_name}"

    {team_ids, errors} = send_org_teams_to_github(repo, org_teams, github_access_token)

    results =
      if length(errors) > 0 do
        errors =
          Enum.map(errors, fn {:error, team, message} -> "#{team}: #{message}" end)
          |> Enum.join("\n")

        Map.update(results, :errors, %{}, fn x -> Map.put(x, :github_org_teams, errors) end)
      else
        results
      end

    results =
      if length(team_ids) > 0 do
        Map.put(results, :github_org_teams, true)
        |> Map.update(:success, %{}, fn x ->
          Map.put(x, :github_org_teams, "Github Teams Added")
        end)
      else
        results
      end

    results
  end

  defp add_org_teams(results, _, _, _), do: results

  defp send_org_teams_to_github(repo, teams, github_access_token) do
    teams
    |> String.split([",", " "], trim: true)
    |> Enum.map(fn team ->
      params = %{access_token: github_access_token, repo: repo, team: team}

      case Github.add_team_to_repo(params) do
        {:ok, _} ->
          {:ok, team, "team added"}

        {:error, message} ->
          {:error, team, message}
      end
    end)
    |> Enum.split_with(fn
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end)
  end

  defp add_webhook(
         %{github_repo: _} = results,
         params,
         webhook_key,
         success_message
       ) do
    case Github.create_webhook(params) do
      {:ok, _} ->
        Map.put(results, webhook_key, true)
        |> Map.update(:success, %{}, fn x -> Map.put(x, webhook_key, success_message) end)

      {:error, message} ->
        Map.update(results, :errors, %{}, fn x -> Map.put(x, webhook_key, message) end)
    end
  end

  defp add_webhook(results, _, _, _) do
    results
  end

  defp lintron_params(project_name, access_token, org_name) do
    %{
      name: "web",
      repo: "#{org_name}/#{project_name}",
      url: Application.get_env(:slax, :lintron)[:url],
      secret: Application.get_env(:slax, :lintron)[:secret],
      events: ["pull_request"],
      access_token: access_token
    }
  end

  defp board_checker_params(project_name, access_token, org_name) do
    %{
      name: "web",
      repo: "#{org_name}/#{project_name}",
      url: Application.get_env(:slax, :board_checker)[:url],
      secret: Application.get_env(:slax, :board_checker)[:secret],
      events: ["*"],
      access_token: access_token
    }
  end
end
