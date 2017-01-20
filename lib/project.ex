defmodule Slax.Project do

  def new_project(name, github_access_token) do
    %{errors: %{}, success: %{}}
    |> parse_project_name(name)
    |> create_github_repo(github_access_token)
    |> create_slack_channel
    |> add_lintron(github_access_token)
    |> add_board_checker(github_access_token)
  end

  defp parse_project_name(results, text) do
    case Regex.run(~r/^[a-zA-Z0-9\-_]{3,21}$/, text) do
      [project_name] ->
        Map.put(results, :project_name, project_name)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :project_name, "Project Name Parsed") end)

      _ ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :project_name, "Invalid Project Name") end)
    end
  end

  defp create_github_repo(%{ project_name: project_name } = results, github_access_token) do
    case Github.create_repo(project_name, github_access_token) do
      {:ok, repo_url} ->
        Map.put(results, :repo_url, repo_url)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :github_repo, "Repo Created: #{repo_url}") end)
      {:error, message} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :github_repo, message) end)
    end
  end

  defp create_github_repo(results, _) do
    results
  end

  defp create_slack_channel(%{ project_name: project_name } = results) do
    case Slack.create_channel(String.lower(project_name)) do
      {:ok, channel} ->
        Map.put(results, :slack_channel, channel["name"])
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :slack_channel, "Channel Created: ##{channel["name"]}") end)
      {:error, message} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :slack_channel, message) end)
    end
  end

  defp create_slack_channel(results, _) do
    results
  end

  defp add_lintron(%{ project_name: project_name, repo_url: _ } = results, github_access_token) do
    case Github.create_webhook(lintron_params(project_name, github_access_token)) do
      {:ok, _} ->
        Map.put(results, :lintron, true)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :lintron, "Lintron Created") end)
      {:error, _} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :lintron, "Unable to add Lintron") end)
    end
  end

  defp add_lintron(results, _) do
    results
  end

  defp add_board_checker(%{ project_name: project_name, repo_url: _ } = results, github_access_token) do
    case Github.create_webhook(lintron_params(project_name, github_access_token)) do
      {:ok, _} ->
        Map.put(results, :board_checker, true)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :lintron, "Board Checker Created") end)
      {:error, _} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :board_checker, "Unable to add Board Checker") end)
    end
  end

  defp add_board_checker(results, _) do
    results
  end

  defp lintron_params(project_name, access_token) do
    %{
      repo: project_name,
      url: Application.get_env(:slax, :lintron)[:url],
      secret: Application.get_env(:slax, :lintron)[:secret],
      events: ["pull_request"],
      access_token: access_token
      }
  end

  defp board_checker_params(project_name, access_token) do
    %{
      repo: project_name,
      url: Application.get_env(:slax, :board_checker)[:url],
      secret: Application.get_env(:slax, :board_checker)[:secret],
      events: ["*"],
      access_token: access_token
    }
  end

  def format_results(results) do
    [:project_name, :repo_url, :slack_channel, :lintron, :board_checker]
    |> Enum.map(&format_result(results, &1))
    |> Enum.join("\n")
  end

  def format_result(results, key) do
    case results[key] do
      nil ->
        results[:errors][key]
      _ ->
        results[:success][key]
    end
  end



end
