defmodule Slax.Commands.GithubCommands do
  @moduledoc """
  Common functions for github commands
  """

  @steps [
    :project_name,
    :github_repo,
    :github_org_teams,
    :slack_channel,
    :lintron,
    :board_checker,
    :reusable_stories
  ]

  alias Slax.{Github}

  @doc """
  Accepts a results map and the potential name of a new github repo.
  If the name is a valid github repo name, it will return a new result map
  containing the `project_name` as well as a key indicating that the `project_name`
  step is complete
  """
  def parse_project_name(results, text) do
    case Regex.run(~r/^[a-zA-Z0-9\-_]{3,21}$/, text) do
      [project_name] ->
        results
        |> Map.put(:project_name, project_name)
        |> Map.update(:success, %{}, fn x -> Map.put(x, :project_name, "Project Name Parsed") end)

      _ ->
        Map.update(results, :errors, %{}, fn x ->
          Map.put(x, :project_name, "Invalid Project Name")
        end)
    end
  end

  @doc """
  Pulls all issue templates from a story repo that are included in `story_paths`.
  It then uses these templates to create issues in a newly created github repository,
  If there is no github repository the function will exit early. The sleep avoids github rate limit abuse err.
  """
  def create_reusable_stories(
        %{project_name: project_name, github_repo: _} = results,
        github_access_token,
        org_name,
        story_repo,
        story_paths
      ) do
    repo = "#{org_name}/#{project_name}"

    :timer.sleep(1500)

    case Github.fetch_tree(%{access_token: github_access_token, repo: story_repo}) do
      {:ok, data} ->
        {blobs, tree_errors} = process_tree(data, story_repo, story_paths, github_access_token)
        {parsed_issues, parse_errors} = decode_blobs(blobs)

        {issue_ids, github_errors} =
          send_issues_to_github(repo, parsed_issues, github_access_token)

        errors = tree_errors ++ parse_errors ++ github_errors

        results = update_results_with_errors(errors, results)

        results = update_results_with_issues(issue_ids, results)

        results

      {:error, message} ->
        Map.update(results, :errors, %{}, fn x -> Map.put(x, :reusable_stories, message) end)
    end
  end

  def create_reusable_stories(results, _, _, _, _), do: results

  defp update_results_with_errors(errors, results) do
    if length(errors) > 0 do
      errors =
        Enum.map_join(errors, "\n", fn {:error, path, message} -> "#{path}: #{message}" end)

      Map.update(results, :errors, %{}, fn x -> Map.put(x, :reusable_stories, errors) end)
    else
      results
    end
  end

  defp update_results_with_issues(issue_ids, results) do
    if length(issue_ids) > 0 do
      results
      |> Map.put(:reusable_stories, true)
      |> Map.update(:success, %{}, fn x ->
        Map.put(x, :reusable_stories, "Reuseable Stories Created")
      end)
    else
      results
    end
  end

  defp process_tree(data, story_repo, story_paths, github_access_token) do
    data
    |> Map.get("tree", [])
    |> Enum.filter(fn x ->
      x["type"] == "blob" && String.ends_with?(x["path"], ".md") &&
        String.starts_with?(x["path"], Keyword.values(story_paths))
    end)
    |> Enum.map(fn x ->
      case Github.fetch_blob(%{
             access_token: github_access_token,
             repo: story_repo,
             sha: x["sha"]
           }) do
        {:ok, data} ->
          {:ok, x["path"], data["content"]}

        {:error, message} ->
          {:error, x["path"], message}
      end
    end)
    |> Enum.split_with(fn
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end)
  end

  defp decode_blobs(blobs) do
    blobs
    |> Enum.map(fn {:ok, path, content} ->
      with {:ok, issue} <- Base.decode64(content |> String.replace("\n", "")),
           {:ok, front_matter, body} <- YamlFrontMatter.parse(issue) do
        {:ok, path, front_matter, body}
      else
        :error ->
          {:error, path, "Unable to parse content"}

        {:error, message} ->
          {:error, path, message}
      end
    end)
    |> Enum.split_with(fn
      {:ok, _, _, _} -> true
      {:error, _, _} -> false
    end)
  end

  defp send_issues_to_github(repo, issues, github_access_token) do
    issues
    |> Enum.map(fn {:ok, path, front_matter, body} ->
      params = %{
        access_token: github_access_token,
        repo: repo,
        title: front_matter["title"],
        labels: List.wrap(Map.get(front_matter, "labels", [])),
        body: body
      }

      case Github.create_issue(params) do
        {:ok, data} ->
          {:ok, path, data}

        {:error, message} ->
          {:error, path, message}
      end
    end)
    |> Enum.split_with(fn
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end)
  end

  @doc """
  Formats results map to be displayed nicely within Slack
  """
  @spec format_results(map) :: binary
  def format_results(results) do
    @steps
    |> Enum.map_join("\n", &format_result(results, &1))
  end

  defp format_result(results, key) do
    message =
      case results[key] do
        nil ->
          results[:errors][key]

        _ ->
          results[:success][key]
      end

    "#{key_to_display_name(key)}: #{message}"
  end

  defp key_to_display_name(key) do
    case key do
      :project_name ->
        "Project Name"

      :github_repo ->
        "Github"

      :github_org_teams ->
        "Github Teams"

      :slack_channel ->
        "Slack"

      :lintron ->
        "Lintron"

      :board_checker ->
        "Board Checker"

      :reusable_stories ->
        "Reusable Stories"

      _ ->
        ""
    end
  end
end
