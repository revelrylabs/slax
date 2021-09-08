defmodule Slax.Slack.Messages.AppHome do
  @moduledoc """
  Slack App Home
  """
  alias Slax.Shoutouts
  alias Slax.Slack.Request
  alias Slax.Teams
  alias Slax.Users

  def call(%{"event" => %{"user" => user_id}, "team_id" => team_id}) do
    team = Teams.get_team(slack_id: team_id)
    user = Users.get_user(slack_id: user_id)
    shoutouts_given = Shoutouts.count_shoutouts(sender_id: user.id)
    shoutouts_received = Shoutouts.count_shoutouts(receiver: user.id)
    shoutouts = Shoutouts.list_shoutouts(receiver: user.id)

    view =
      view(%{
        given: shoutouts_given,
        received: shoutouts_received,
        shoutouts: shoutouts
      })

    Request.post("views.publish", %{user_id: user_id, view: view}, team.token)
    :ok
  end

  defp view(params) do
    %{
      type: "home",
      blocks: shoutouts(params) ++ stats(params) ++ link_to_account()
    }
  end

  defp link_to_account do
    [
      %{
        type: "section",
        text: %{type: "plain_text", text: " "}
      },
      %{
        type: "section",
        text: %{type: "plain_text", text: " "}
      },
      %{
        type: "actions",
        elements: [
          %{
            type: "button",
            url: "https://slax.ngrok.io",
            text: %{
              type: "plain_text",
              text: "Go to Slax Dashboard"
            }
          }
        ]
      }
    ]
  end

  defp stats(%{given: given, received: received}) do
    [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "Statistics (past 7 days)",
          emoji: true
        }
      },
      %{
        type: "divider"
      },
      %{
        type: "section",
        fields: [
          %{
            type: "mrkdwn",
            text: "Given: #{given}"
          },
          %{
            type: "mrkdwn",
            text: "Received: #{received}"
          }
        ]
      }
    ]
  end

  defp shoutouts(%{shoutouts: shoutouts}) do
    [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "Shoutouts",
          emoji: true
        }
      },
      %{type: "divider"},
      %{
        type: "section",
        text: %{type: "plain_text", text: " "}
      }
    ] ++ Enum.flat_map(shoutouts, &shoutout(&1))
  end

  defp shoutout(%{message: message, sender: sender, receivers: receivers}) do
    [
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: message
        }
      },
      %{
        type: "context",
        elements: [
          %{type: "mrkdwn", text: "Submitted by"},
          %{type: "image", image_url: sender.avatar, alt_text: sender.name},
          %{type: "mrkdwn", text: sender.name}
        ]
      },
      %{
        type: "section",
        text: %{type: "plain_text", text: " "}
      },
      %{
        type: "section",
        text: %{type: "plain_text", text: " "}
      }
    ] ++ also_received_by(receivers)
  end

  defp also_received_by([_]), do: []

  defp also_received_by(receivers) do
    Enum.map(receivers, fn receiver ->
      %{
        type: "context",
        elements: [
          %{
            type: "mrkdwn",
            text: "Also received by"
          },
          %{
            type: "image",
            image_url: receiver.avatar,
            alt_text: receiver.name
          }
        ]
      }
    end)
  end
end
