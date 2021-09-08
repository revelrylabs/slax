defmodule Slax.Slack.Announce do
  @moduledoc """
  Defines a worker that will announce a shoutout to a slack channel.
  """

  use Oban.Worker,
    queue: :announce,
    max_attempts: 10

  require Logger

  alias Ecto.Multi
  alias Slax.Repo
  alias Slax.Schemas.Team
  alias Slax.Schemas.User
  alias Slax.Shoutouts
  alias Slax.Slack.Request
  alias Slax.Users

  @impl Oban.Worker
  def perform(%{args: %{"shoutout_id" => shoutout_id, "user_ids" => user_ids}}) do
    Enum.each(user_ids, &update_user(&1, shoutout_id))
    announce_shoutout(shoutout_id)
  end

  defp update_user(user_id, shoutout_id) do
    with shoutout <- Shoutouts.get_shoutout(id: shoutout_id),
         user <- Users.get_user(id: user_id),
         {:ok, profile} <- fetch_profile(user.slack_id, shoutout.team.token),
         {:ok, team} <- fetch_team(shoutout.team.slack_id, shoutout.team.token),
         {:ok, user_attrs} <- get_user_attrs(profile),
         {:ok, team_attrs} <- get_team_attrs(team) do
      Multi.new()
      |> Multi.update(:user, User.changeset(user, user_attrs))
      |> Multi.update(:team, Team.changeset(shoutout.team, team_attrs))
      |> Repo.transaction()
    else
      error ->
        Logger.warn("""
        Fetching Data Failed
        ---
        #{inspect(error, pretty: true)}
        """)
    end
  end

  defp announce_shoutout(shoutout_id) do
    shoutout = Shoutouts.get_shoutout(id: shoutout_id)
    token = shoutout.team.token

    payload_shoutout = %{
      channel: shoutout.channel,
      icon_emoji: ":tada:",
      text: "#{shoutout.sender.name} gave a shoutout to #{receiver_names(shoutout.receivers)}!",
      attachments: [
        %{
          color: "#f2c744",
          blocks: blocks(shoutout)
        }
      ]
    }

    shoutout_results = Request.post("chat.postMessage", payload_shoutout, token)

    case shoutout_results do
      {:ok, %{"ok" => true}, 200} ->
        :ok

      error ->
        Logger.warn("""
          Announcement Error
          ---
          #{inspect(error)}
        """)

        {:error, error}
    end
  end

  defp blocks(%{message: message, sender: sender, receivers: receivers}) do
    [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "Shoutout :tada: :tada: :tada:",
          emoji: true
        }
      },
      %{
        type: "context",
        elements: [
          %{
            type: "plain_text",
            text: "#{sender.name} gave a shoutout to #{receiver_names(receivers)}!"
          }
        ]
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: message
        }
      },
      %{
        type: "divider"
      },
      %{
        type: "context",
        elements: people_involved(sender, receivers)
      }
    ]
  end

  defp receiver_names([receiver]) do
    receiver.name
  end

  defp receiver_names([receiver1, receiver2]) do
    "#{receiver1.name} and #{receiver2.name}"
  end

  defp receiver_names([receiver | receivers]) do
    comma_separated =
      receivers
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    "#{comma_separated} and #{receiver.name}"
  end

  defp people_involved(sender, receivers) do
    Enum.reduce([sender] ++ receivers, [], fn user, acc ->
      acc ++
        [
          %{
            type: "image",
            image_url: user.avatar,
            alt_text: user.name
          },
          %{
            type: "mrkdwn",
            text: "<@#{user.slack_id}>"
          }
        ]
    end)
  end

  def get_user_attrs(profile) do
    {:ok,
     %{
       name: get_name(profile),
       avatar: Map.get(profile, "image_192")
     }}
  end

  def get_team_attrs(team) do
    {:ok,
     %{
       name: Map.get(team, "name"),
       avatar: get_in(team, ["icon", "image_132"])
     }}
  end

  def fetch_team(slack_id, token) do
    {:ok, %{"ok" => true, "team" => team}, 200} =
      Request.get("team.info", %{team: slack_id}, token)

    {:ok, team}
  end

  def fetch_profile(slack_id, token) do
    with {:ok, %{"ok" => true, "profile" => profile}, 200} <-
           Request.get("users.profile.get", %{user: slack_id}, token) do
      {:ok, profile}
    end
  end

  defp get_name(%{"display_name" => display_name}) when display_name != "" do
    display_name
  end

  defp get_name(%{"real_name" => real_name}) when real_name != "" do
    real_name
  end

  defp get_name(_), do: nil
end
