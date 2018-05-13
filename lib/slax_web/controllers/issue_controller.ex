defmodule SlaxWeb.IssueController do
  use SlaxWeb, :controller
  alias Slax.Integrations

  plug(Slax.Plugs.VerifySlackToken, :issue)
  plug(Slax.Plugs.VerifyUser)

  def start(conn, %{"text" => ""}) do
    text(conn, """
    *Issue commands:*
    /issue <org/repo> <issue title> [issue body preceded by a newline]
    """)
  end

  def start(conn, %{"text" => text}) do
    case Regex.run(~r/(.+?\/[^ ]+) (.*)\n?([\s\S]*)?/, text) do
      [_, repo, title, body] ->
        github_response =
          Integrations.github().create_issue(%{
            title: title,
            body: body,
            repo: repo,
            access_token: conn.assigns.current_user.github_access_token
          })

        response =
          case github_response do
            {:ok, issue_link} -> "Issue created: #{issue_link}"
            {:error, message} -> "Uh oh! #{message}"
          end

        json(conn, %{
          response_type: "in_channel",
          text: response
        })

      _ ->
        text(conn, "Invalid parameters, org/repo combo and title is required")
    end
  end
end
