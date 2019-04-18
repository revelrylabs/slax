defmodule Slax.Scheduler do
  use Quantum.Scheduler,
    otp_app: :slax

  alias Slax.{ProjectRepos, Github, Commands.GithubCommands, Slack}

  def start() do
    repos = ProjectRepos.get_repos()
    IO.inspect("RUNNING!!!!!!!!!!!!!!!!")
    repos
      |> Enum.map(fn repo ->
      params = %{
        repo: repo.repo_name,
        access_token: Application.get_env(:slax, Slax.Github)[:api_token],
        org: repo.org_name
      }

      formatted_response =
        Github.fetch_issues(params)
        |> GithubCommands.format_issues()


      Slack.post_message_to_channel(%{
        text: formatted_response,
        channel_name: "#"<>repo.channel_name
      })
    end)
  end
end
