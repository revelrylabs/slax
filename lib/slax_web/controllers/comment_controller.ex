defmodule SlaxWeb.CommentController do
  @moduledoc """
  Entry point to create Github comments
  """
  alias Slax.Integrations

  use SlaxWeb, :controller

  plug(Slax.Plugs.VerifySlackToken, token: :comment)
  plug(Slax.Plugs.VerifyUser)

  def start(conn, %{"text" => ""}) do
    text(conn, """
    *Comment commands:*
    /comment <org/repo#issue_number> <comment body>
    """)
  end

  def start(conn, %{"text" => text}) do
    # This is separate to easily keep it in sync with slack-agile
    issue_number_pattern = "([\\w-]+)/([\\w-]+)#([0-9]+)"

    case Regex.run(~r/#{issue_number_pattern}\s+([\s\S]+)/, text) do
      [_, org, repo, issue_number, comment_body] ->
        github_response =
          Integrations.github().create_comment(%{
            org: org,
            repo: repo,
            issue_number: issue_number,
            body: comment_body,
            access_token: conn.assigns.current_user.github_access_token
          })

        response =
          case github_response do
            {:ok, issue_link} -> "Comment created: #{issue_link}"
            {:error, message} -> "Uh oh! #{message}"
          end

        json(conn, %{
          response_type: "in_channel",
          text: response
        })

      _ ->
        text(conn, "Invalid parameters, org/repo#issue_number and comment body are required")
    end
  end
end
