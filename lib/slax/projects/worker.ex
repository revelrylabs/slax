defmodule Slax.ProjectRepos.Worker do
  @moduledoc """
  Job for sending reminder messages to Slack to update an expiring access token.
  """
  use Oban.Worker, queue: :project_repos

  alias Slax.ProjectRepos
  alias Slax.Slack

  require Logger

  @impl Oban.Worker

  def perform(%{
        args: %{
          "action" => "send_reminder",
          "expiration_date" => expiration_date,
          "repo_list" => repo_list
        }
      }) do
    now = Date.utc_today()

    if Date.compare(Date.from_iso8601!(expiration_date), now) == :eq do
      Slack.post_message_to_channel(
        "Access token(s) for the following repos are expired: #{repo_list}. Please replace them using the /token command"
      )
    else
      Slack.post_message_to_channel(
        "Access token(s) for the following repos will expire on #{Timex.format!(Date.from_iso8601!(expiration_date), "{M}-{D}-{YYYY}")}: #{repo_list}. Please replace them using the /token command"
      )
    end
  end

  def perform(_) do
    ProjectRepos.list_needs_reminder_message()
    |> Enum.group_by(& &1.expiration_date)
    |> Enum.map(fn {expiration_date, repo_list} ->
      new(%{
        action: "send_reminder",
        expiration_date: expiration_date,
        repo_list:
          Enum.reduce(repo_list, "", fn repo, repo_string ->
            if repo_string == "" do
              "`#{repo.org_name}/#{repo.repo_name}`"
            else
              repo_string <> " `#{repo.org_name}/#{repo.repo_name}`"
            end
          end)
      })
    end)
    |> Oban.insert_all()

    :ok
  end
end
