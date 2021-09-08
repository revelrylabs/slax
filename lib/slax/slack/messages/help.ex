defmodule Slax.Slack.Messages.Help do
  @moduledoc """
  functions for showing the help message
  """

  alias Slax.Slack.Request
  alias Slax.Teams

  def call(%{
        "callback_id" => "help",
        "trigger_id" => trigger_id,
        "user" => %{"id" => user_id, "team_id" => team_slack_id}
      }) do
    send_slax_help(team_slack_id, user_id, user_id, trigger_id)

    :ok
  end

  # help slash command
  def call(%{
        "command" => "/slax",
        "text" => "help" <> _,
        "trigger_id" => trigger_id,
        "user_id" => slack_sender_id,
        "team_id" => team_slack_id,
        "channel_id" => channel
      }) do
    send_slax_help(team_slack_id, slack_sender_id, channel, trigger_id)

    :ok
  end

  defp send_slax_help(team_slack_id, user_slack_id, channel, trigger_id) do
    team = Teams.get_team(slack_id: team_slack_id)

    attrs = %{
      channel: channel,
      blocks: view(),
      trigger_id: trigger_id,
      text: "Hey 👋 I'm PeerBot, click to learn how to shoutout",
      slack_team_id: team_slack_id,
      user: user_slack_id
    }

    Request.post("chat.postEphemeral", attrs, team.token)
  end

  def view do
    [
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "Hey there 👋 I'm PeerBot. I'm here to help you shoutout your teammates in Slack:"
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text:
            "*1️⃣ Use the `/slax` command*. Type `/slax shoutout` to give shoutout to someone via Slack. Try it out by using the `/slax shoutout` command in any channel."
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text:
            "*2️⃣ Use the _Shoutout_ action.* Select `Shoutout` in a message's context menu. Try it out by selecting the _Shoutout_ action in a new message (example shown below)."
        }
      }
    ]
  end
end
