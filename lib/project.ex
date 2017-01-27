defmodule Slax.Project do
  @steps [
    :project_name,
    :github_repo,
    :slack_channel,
    :lintron,
    :board_checker,
    :resuseable_stories,
    :ten_thousand_feet
  ]

  def new_project(org_name, name, github_access_token, story_repo, story_paths) do
    %{errors: %{}, success: %{}}
    |> parse_project_name(name)
    |> create_github_repo(github_access_token, org_name)
    |> create_slack_channel
    |> create_10000ft_project
    |> add_lintron(github_access_token, org_name)
    |> add_board_checker(github_access_token, org_name)
    |> create_reusable_stories(github_access_token, org_name, story_repo, story_paths)
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

  defp create_github_repo(%{ project_name: project_name } = results, github_access_token, org_name) do
    case Github.create_repo(%{name: project_name, access_token: github_access_token, org_name: org_name}) do
      {:ok, repo_url} ->
        Map.put(results, :github_repo, repo_url)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :github_repo, "Github Repo Created: #{repo_url}") end)
      {:error, message} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :github_repo, message) end)
    end
  end

  defp create_github_repo(results, _) do
    results
  end

  defp create_slack_channel(%{ project_name: project_name } = results) do
    case Slack.create_channel(String.downcase(project_name)) do
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

  defp create_10000ft_project(%{ project_name: project_name } = results) do
    case TenThousandFeet.create_project(project_name) do
      :ok ->
        Map.put(results, :ten_thousand_feet, true)
        |> Map.update(:success, %{}, fn(x) -> Map.put(x, :ten_thousand_feet, "10000ft Project Created: #{project_name}") end)
      {:error, message} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :ten_thousand_feet, message) end)
    end
  end

  defp create_10000ft_project(results) do
    results
  end

  defp add_lintron(%{ project_name: project_name, github_repo: _ } = results, github_access_token, org_name) do
    case Github.create_webhook(lintron_params(project_name, github_access_token, org_name)) do
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

  defp add_board_checker(%{ project_name: project_name, github_repo: _ } = results, github_access_token, org_name) do
    case Github.create_webhook(board_checker_params(project_name, github_access_token, org_name)) do
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

  defp create_reusable_stories(%{ project_name: project_name, github_repo: _ } = results, github_access_token, org_name, story_repo, story_paths) do
    repo = "#{org_name}/#{project_name}"

    case Github.fetch_tree(%{ access_token: github_access_token, repo: story_repo }) do
      {:ok, data} ->
        { blobs, tree_errors } = process_tree(data, story_repo, story_paths, github_access_token)
        { parsed_issues, parse_errors } = decode_blobs(blobs)
        { issue_ids, github_errors } = send_issues_to_github(repo, parsed_issues, github_access_token)

        errors = tree_errors ++ parse_errors ++ github_errors


        results = if length(errors) > 0 do
          errors = Enum.map(errors, fn({:error, path, message}) -> "#{path}: #{message}" end )
          |> Enum.join("\n")
          Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :resuseable_stories, errors) end)
        else
          results
        end

        results = if length(issue_ids) > 0 do
          results = Map.put(results, :reusable_stories, true)
          |> Map.update(:success, %{}, fn(x) -> Map.put(x, :resuseable_stories, "Reuseable Stories Created") end)
        else
          results
        end

        results

      {:error, message} ->
        Map.update(results, :errors, %{}, fn(x) -> Map.put(x, :resuseable_stories, message) end)
    end
  end

  defp process_tree(data, story_repo, story_paths, github_access_token) do
    data
    |> Enum.filter(fn(x) -> x["type"] == "blob" && String.ends_with?(x["path"], ".md") end)
    |> Enum.filter(fn(x) -> String.starts_with?(x["path"], Keyword.values(story_paths) ) end)
    |> Enum.map(fn(x) ->
      case Github.fetch_tree(%{ access_token: github_access_token, repo: story_repo, sha: x["sha"]}) do
        {:ok, data} ->
          {:ok, x["path"], data["content"]}
        {:error, message} ->
          {:error, x["path"], message}
      end
    end)
    |> Enum.split_with(fn
      ({:ok, _, _}) -> true
      ({:error, _, _}) -> false
    end)
  end

  defp decode_blobs(blobs) do
    blobs
    |> Enum.map(fn({:ok, path, content}) ->
      with {:ok, issue} <- Base.decode64(content),
      {:ok, front_matter, body} <- YamlFrontMatter.parse(issue)
        do
        {:ok, path, front_matter, body}
        else
          :error ->
            {:error, path, "Unable to parse content"}
          {:error, message} ->
            {:error, path, message}
      end
    end)
    |> Enum.split_with(fn
      ({:ok, _, _, _}) -> true
      ({:error, _, _}) -> false
    end)
  end

  defp send_issues_to_github(repo, issues, github_access_token) do
    issues
    |> Enum.map(fn({:ok, path, front_matter, body}) ->
      params = %{ access_token: github_access_token, repo: repo, title: front_matter["title"], labels: List.wrap(Map.get(front_matter, "labels", [])), body: body }
      case Github.create_issue(params) do
        {:ok, data} ->
          {:ok, path, data}
        {:error, message} ->
          {:error, path, message}
      end
    end)
    |> Enum.split_with(fn
      ({:ok, _, _}) -> true
      ({:error, _}) -> false
    end)
  end


  def format_results(results) do
    @parts
    |> Enum.map(&format_result(results, &1))
    |> Enum.join("\n")
  end

  defp format_result(results, key) do
    message = case results[key] do
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
      :repo_url ->
        "Github"
      :slack_channel ->
        "Slack"
      :lintron ->
        "Lintron"
      :board_checker ->
        "Board Checker"
      :resuseable_stories ->
        "Reuseable Stories"
      :ten_thousand_feet ->
        "10000ft"
      _ ->
        ""
    end
  end



end
