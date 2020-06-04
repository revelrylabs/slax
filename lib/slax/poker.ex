defmodule Slax.Poker do
  use Slax.Context
  alias Slax.{Github, Poker.Round}

  def start_round(channel_name, issue) do
    repo_and_issue = Regex.replace(~r".*?(\w+)/(\w+)/issues/(\d+)$", issue["url"], "\\1/\\2/\\3")

    %Round{}
    |> Round.changeset(%{
      channel: channel_name,
      issue: repo_and_issue
    })
    |> Repo.insert()

    response = """
      Planning poker for #{repo_and_issue}.
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

    client = Tentacat.Client.new(%{access_token: Github.api_token()})

    case Tentacat.Issues.update(client, org, repo, issue, %{labels: ["Score: #{score}"]}) do
      {200, _issue, _http_response} ->
        :ok

      {_response_code, %{"message" => error_message}, _http_response} ->
        {:error, error_message}
    end
  end
end
