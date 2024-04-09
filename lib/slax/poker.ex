defmodule Slax.Poker do
  use Slax.Context
  alias Slax.{Github, Poker.Round, ProjectRepos}

  def start_round(channel_name, issue) do
    repo_and_issue =
      Regex.replace(~r".*/repos/(\S+)/(\S+)/issues/(\d+)$", issue["url"], "\\1/\\2/\\3")

    %Round{}
    |> Round.changeset(%{
      channel: channel_name,
      issue: repo_and_issue
    })
    |> Repo.insert()

    labels = Enum.map_join(issue["labels"], ", ", & &1["name"])
    pr = if Map.has_key?(issue, "pull_request"), do: "(PR) "

    response = """
      Planning poker for #{repo_and_issue}.
      ---
      #{pr}#{issue["number"]}: #{issue["title"]} (#{labels})
      ---
      #{issue["body"]}
      #{issue["html_url"]}
      This issue has #{issue["comments"]} #{Inflex.inflect("comment", issue["comments"])}

      ---
      Reminder: all of the work counts for the complexity score. Getting
      clarity on the issue, project management, development, writing tests,
      design, QA, UAT, release to production, and any other work all count
      for the complexity score!
    """

    {:ok, response}
  end

  @doc """
  Closes all open rounds for a channel
  """
  def end_current_round_for_channel(channel_name) do
    from(
      round in Round,
      where: round.closed == false,
      where: round.channel == ^channel_name
    )
    |> Repo.update_all(set: [closed: true])
    |> case do
      {number_updated, _} -> {:ok, number_updated}
      _ -> {:error, "Could not close poker for #{channel_name}"}
    end
  end

  def get_current_round_for_channel(channel_name) do
    from(
      round in Round,
      where: round.closed == false,
      where: round.channel == ^channel_name
    )
    |> preload([:estimates])
    |> Repo.one()
  end

  def decide(round, score) do
    {org, repo, issue} = Github.parse_repo_org_issue(round.issue)

    client =
      case ProjectRepos.get_by_repo(repo) do
        %{token: token} when not is_nil(token) ->
          Tentacat.Client.new(%{access_token: token})

        _ ->
          Tentacat.Client.new(%{access_token: Github.api_token()})
      end

    with {200, labels, _http_response} <- Tentacat.Issues.Labels.list(client, org, repo, issue),
         :ok <- maybe_delete_label(labels, client, org, repo, issue),
         {200, _issue, _http_response} <-
           Tentacat.Issues.Labels.add(client, org, repo, issue, ["Points: #{score}"]) do
      :ok
    else
      {_response_code, %{"message" => error_message}, _http_response} ->
        {:error, error_message}
    end
  end

  defp maybe_delete_label(labels, client, org, repo, issue) do
    label =
      Enum.find(labels, fn
        %{"name" => "Points: " <> _score} -> true
        _label -> false
      end)

    if not is_nil(label) do
      case Tentacat.Issues.Labels.remove(client, org, repo, issue, URI.encode(label["name"])) do
        {200, _issue, _http_response} ->
          :ok

        {response_code, message, http_response} ->
          {response_code, message, http_response}
      end
    else
      :ok
    end
  end
end
