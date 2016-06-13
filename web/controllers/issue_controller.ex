defmodule Slax.IssueController do
  use Slax.Web, :controller

  plug Slax.Plugs.VerifySlackToken, :issue
  plug Slax.Plugs.VerifyUser

  def start(conn, %{"text" => ""}) do
    text conn, """
    *Issue commands:*
    /issue <org/repo> <issue title> [issue body preceded by a newline]
    """
  end

  def start(conn, %{"text" => text}) do
    [_, repo, title, body] = Regex.run(~r/(.+\/[^ ]+) (.*)\n?(.*)?/, text)

    github_response = Github.create_issue(%{
      title: title,
      body: body,
      repo: repo,
      access_token: conn.assigns.current_user.github_access_token
    })

    response = case github_response do
      {:ok, issue_link} -> "Issue created: #{issue_link}"
      {:error, message} -> "Uh oh! #{message}"
    end

    json conn, %{
      response_type: "in_channel",
      text: response
    }
  end
end
