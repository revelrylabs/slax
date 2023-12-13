defmodule SlaxWeb.Disable do
  @moduledoc """
  A module that handles Slack websocket payloads for disabling Slax interactions and
  builds modal views for slack https://api.slack.com/reference/surfaces/views
  """

  alias Slax.Slack
  alias Slax.Channels

  def handle_payload(
        %{
          "type" => "shortcut",
          "callback_id" => "slax_disable"
        } = payload
      ) do
    trigger_id = payload["trigger_id"]

    view = build_disable_view()
    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(
        %{
          "type" => "shortcut",
          "callback_id" => "slax_enable"
        } = payload
      ) do
    trigger_id = payload["trigger_id"]
    view = build_enable_view()

    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(
        %{
          "type" => "view_submission",
          "view" => %{
            "callback_id" => "disable_view"
          }
        } = payload
      ) do
    trigger_id = payload["trigger_id"]
    values = payload["view"]["state"]["values"]
    %{name: name} = parse_state_values(Map.values(values))

    valid_channel =
      Enum.find(Slack.get_channels(%{trigger_id: trigger_id}), &(&1["name"] == name))

    case valid_channel do
      nil ->
        :error

      channel ->
        channel_id = Map.get(channel, "id")

        Channels.create_or_update_channel(channel_id, %{
          name: name,
          disabled: true
        })

        :ok
    end
  end

  def handle_payload(
        %{
          "type" => "view_submission",
          "view" => %{
            "callback_id" => "enable_view"
          }
        } = payload
      ) do
    values = payload["view"]["state"]["values"]
    %{channel_id: channel_id, name: name} = parse_state_values(Map.values(values))

    Channels.create_or_update_channel(channel_id, %{
      name: name,
      disabled: false
    })

    :ok
  end

  defp parse_state_values([
         %{
           "channel_select" => %{
             "selected_option" => %{
               "text" => name,
               "value" => channel_id
             }
           }
         }
       ]) do
    %{
      channel_id: channel_id,
      name: name["text"]
    }
  end

  defp parse_state_values([
         %{
           "channel_input" => %{
             "value" => name
           }
         }
       ]) do
    %{
      name: name
    }
  end

  defp build_disable_view() do
    %{
      type: "modal",
      callback_id: "disable_view",
      title: %{
        type: "plain_text",
        text: "Disable Slax",
        emoji: true
      },
      submit: %{
        type: "plain_text",
        text: "Disable",
        emoji: true
      },
      close: %{
        type: "plain_text",
        text: "Cancel",
        emoji: true
      },
      blocks: [
        %{
          type: "input",
          block_id: "channel_input",
          element: %{
            type: "plain_text_input",
            placeholder: %{
              type: "plain_text",
              text: "Enter the name of a channel (excluding #)",
              emoji: true
            },
            action_id: "channel_input"
          },
          label: %{
            type: "plain_text",
            text: "Channel Name",
            emoji: true
          }
        }
      ]
    }
  end

  defp build_enable_view() do
    case Channels.get_disabled() do
      [] ->
        build_no_channels_view()

      channels ->
        %{
          type: "modal",
          callback_id: "enable_view",
          submit: %{
            type: "plain_text",
            text: "Enable"
          },
          title: %{
            type: "plain_text",
            text: "Enable Slax"
          },
          blocks: [
            %{
              type: "input",
              element: %{
                type: "static_select",
                action_id: "channel_select",
                placeholder: %{
                  type: "plain_text",
                  text: "Select a Channel",
                  emoji: true
                },
                options:
                  Enum.map(channels, fn channel ->
                    %{text: %{type: "plain_text", text: channel.name}, value: channel.channel_id}
                  end)
              },
              label: %{
                type: "plain_text",
                text: "Channels",
                emoji: true
              }
            }
          ]
        }
    end
  end

  defp build_no_channels_view() do
    %{
      type: "modal",
      callback_id: "enable_view",
      title: %{
        type: "plain_text",
        text: "Enable Slax",
        emoji: true
      },
      close: %{
        type: "plain_text",
        text: "Close",
        emoji: true
      },
      blocks: [
        %{
          type: "section",
          text: %{
            type: "plain_text",
            text: "There are no disabled channels.",
            emoji: true
          }
        }
      ]
    }
  end
end
