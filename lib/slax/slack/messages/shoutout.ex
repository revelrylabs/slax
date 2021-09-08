defmodule Slax.Slack.Messages.Shoutout do
  @moduledoc """
  functions for shouting
  """

  alias Slax.Shoutouts
  alias Slax.Slack.Request
  alias Slax.Teams
  alias Slax.Users

  @slack_user_id_pattern ~r/<@([UW].+?)\|(.+?)>/

  def call(%{
        "command" => "/slax",
        "text" => "shoutout" <> text,
        "trigger_id" => trigger_id,
        "team_id" => team_slack_id,
        "channel_id" => channel_id
      }) do
    modal_fields = %{
      users: extract_user_ids(text) |> Jason.encode!(),
      message: extract_message(text),
      channel_id: channel_id
    }

    post(team_slack_id, trigger_id, modal_fields)
  end

  def call(%{
        "callback_id" => "shoutout",
        "trigger_id" => trigger_id,
        "user" => %{"team_id" => team_slack_id}
      }) do
    post(team_slack_id, trigger_id)
  end

  defp post(team_slack_id, trigger_id, modal_fields \\ nil) do
    with %{token: token} <- Teams.get_team(slack_id: team_slack_id) do
      payload = %{view: view(modal_fields), trigger_id: trigger_id}
      Request.post("views.open", payload, token)

      :ok
    end
  end

  def parse_and_insert_shoutout(params) do
    with {:ok, attrs} <- parse_params(params),
         {:ok, _shoutout} <- Shoutouts.insert_shoutout(attrs) do
      :ok
    end
  end

  defp parse_params(%{
         "team" => %{"id" => slack_team_id},
         "user" => %{"id" => slack_sender_id},
         "view" => %{
           "state" => %{
             "values" => %{
               "users" => %{
                 "multi_users_select-action" => %{"selected_users" => slack_receiver_ids}
               },
               "message" => %{"plain_text_input-action" => %{"value" => message}},
               "channel" => %{"channels_select-action" => %{"selected_channel" => channel}}
             }
           }
         }
       }) do
    if slack_sender_id in slack_receiver_ids do
      {:error, "Cannot shoutout yourself."}
    else
      {:ok,
       %{
         slack_team_id: slack_team_id,
         slack_sender_id: slack_sender_id,
         slack_receiver_ids: slack_receiver_ids,
         message: message,
         channel: channel
       }}
    end
  end

  defp parse_params(view) do
    {:error, "Unable to parse view", view}
  end

  defp extract_message(text) do
    user_ids = extract_user_ids(text)

    text
    |> String.replace(@slack_user_id_pattern, &replace_user_ids(&1, user_ids))
    |> String.trim()
  end

  defp replace_user_ids(match, user_ids) do
    for id <- user_ids do
      if String.contains?(match, id) do
        Users.get_user(slack_id: id).name
      else
        ""
      end
    end
  end

  defp extract_user_ids(text) do
    text
    |> String.trim()
    |> String.split(@slack_user_id_pattern, trim: true, include_captures: true)
    |> Enum.filter(&Regex.match?(@slack_user_id_pattern, &1))
    |> Enum.flat_map(&String.split(&1, ~r/<@|\|.+?>/, trim: true))
  end

  defp view(nil) do
    view(%{users: "", message: "", channel_id: ""})
  end

  defp view(%{users: users, message: message, channel_id: channel_id}) do
    Jason.decode!("""
    {
      "callback_id": "shoutout_modal",
      "blocks": [
        {
          "type": "divider"
        },
        {
          "type": "input",
          "block_id": "channel",
          "element": {
            #{initial_channel(channel_id)}
            "type": "channels_select",
            "placeholder": {
              "type": "plain_text",
              "text": "Select channel",
              "emoji": true
            },
            "action_id": "channels_select-action"
          },
          "label": {
            "type": "plain_text",
            "text": "Select Announcement Channel",
            "emoji": true
          }
        },
        {
          "block_id": "users",
          "element": {
            #{initial_users(users)}
            "action_id": "multi_users_select-action",
            "placeholder": {
              "emoji": true,
              "text": "Select users",
              "type": "plain_text"
            },
            "type": "multi_users_select"
          },
          "label": {
            "emoji": true,
            "text": "Teammate(s)",
            "type": "plain_text"
          },
          "type": "input"
        },
        {
          "block_id": "message",
          "element": {
            "action_id": "plain_text_input-action",
            "multiline": true,
            "type": "plain_text_input",
            "initial_value": "#{message}"
          },
          "label": {
            "emoji": true,
            "text": "Message",
            "type": "plain_text"
          },
          "type": "input"
        }
      ],
      "close": {
        "emoji": true,
        "text": "Cancel",
        "type": "plain_text"
      },
      "submit": {
        "emoji": true,
        "text": "Submit",
        "type": "plain_text"
      },
      "title": {
        "emoji": true,
        "text": "Give a shoutout!",
        "type": "plain_text"
      },
      "type": "modal"
    }
    """)
  end

  defp initial_channel(channel_id) do
    if channel_id != "" do
      """
      "initial_channel": "#{channel_id}",
      """
    end
  end

  def initial_users(users) do
    if users != "" do
      """
      "initial_users": #{users},
      """
    end
  end
end
