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
    Task.start_link(fn ->
      trigger_id = payload["trigger_id"]

      slack_channels =
        Enum.map(Slack.get_channels(%{trigger_id: trigger_id}), fn channel ->
          %{channel_id: channel["id"], name: channel["name"], disabled: false}
        end)

      all_channels = Channels.get_all() ++ slack_channels

      enabled_channels =
        all_channels
        |> Enum.uniq_by(& &1.channel_id)
        |> Enum.reject(& &1.disabled)
        |> Enum.sort_by(& &1.name)

      view = build_disable_view(enabled_channels)
      Slack.open_modal(%{trigger_id: trigger_id, view: view})
    end)

    :ok
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
    values = payload["view"]["state"]["values"]
    %{channel_id: channel_id, name: name} = parse_state_values(Map.values(values))

    Channels.create_or_update_channel(channel_id, %{
      name: name,
      disabled: true
    })

    :ok
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

  defp build_disable_view(channels) do
    %{
      type: "modal",
      callback_id: "disable_view",
      submit: %{
        type: "plain_text",
        text: "Disable"
      },
      title: %{
        type: "plain_text",
        text: "Disable Slax"
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
