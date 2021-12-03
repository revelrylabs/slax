defmodule Slax.Scheduler do
  @moduledoc """
  Run the unmoved issue report on a schedule.
  """
  use Quantum, otp_app: :slax

  alias Slax.{Github, ProjectRepos, Slack}
  alias Slax.Commands.{Latency}

  def start() do
    project_repos = ProjectRepos.get_blockerbot_repos()

    project_repos
    |> Enum.each(fn repo ->
      send_repo_to_channel(repo.org_name, repo.repo_name, repo.channel_name)
    end)
  end

  def send_repo_to_channel(org_name, repo_name, channel_name) do
    formatted_response =
      Latency.text_for_org_and_repo(
        org_name,
        repo_name,
        Application.get_env(:slax, Github)[:api_token]
      )

    Slack.post_message_to_channel(%{
      text: formatted_response,
      channel_name: channel_name
    })
  end
end
