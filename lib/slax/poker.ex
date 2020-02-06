defmodule Slax.Poker do

  alias Slax.{Github, Poker.Round, Repo}

  import Ecto.Query

  def start_round(channel_name, repo_and_issue, issue, response_url) do
    %Round{}
    |> Round.changeset(%{
      channel: channel_name,
      issue: issue,
      response_url: response_url
    })
    |> Repo.insert()

    response = """
      Planning poker for #{repo_and_issue}.
      ---
      #{issue["body"]}
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
end
