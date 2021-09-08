defmodule Slax.Slack.WelcomeMessage do
  @moduledoc """
  Defines a worker that will send welcome messages after onboarding.
  """
  use Oban.Worker,
    queue: :welcome_message,
    max_attempts: 10

  alias Slax.Slack.Messages.Help
  alias Slax.Slack.Request

  @impl Oban.Worker
  def perform(%{args: %{"welcome_channel_slack_id" => welcome_channel_slack_id, "token" => token}}) do
    payload_welcome = %{
      channel: welcome_channel_slack_id,
      icon_emoji: ":tada:",
      text: "Thanks for adding me to you workspace 🎉",
      attachments: [
        %{
          color: "#f2c744",
          blocks: Help.view()
        }
      ]
    }

    Request.post("chat.postMessage", payload_welcome, token)
  end
end
