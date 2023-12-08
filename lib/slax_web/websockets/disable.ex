defmodule SlaxWeb.Disable do
  @moduledoc """
  A module that handles Slack websocket payloads for disabling Slax interactions and
  builds modal views for slack https://api.slack.com/reference/surfaces/views
  """

  alias Slax.Slack
  alias Slax.Channels

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "shortcut",
        "callback_id" => "disable_slax"
      }) do
    view = build_disable_view(%{trigger_id: trigger_id})

    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "shortcut",
        "callback_id" => "enable_slax"
      }) do
    view = build_enable_view()

    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(%{
        "trigger_id" => _trigger_id,
        "type" => "view_submission",
        "view" => %{
          "callback_id" => "disable_view",
          "state" => %{
            "values" => values
          }
        }
      }) do
    with %{
           channel_id: channel_id,
           name: name
         } <-
           parse_state_values(Map.values(values)) do
      Channels.create_or_update_channel(channel_id, %{
        name: name,
        disabled: true
      })

      :ok
    end
  end

  def handle_payload(%{
        "trigger_id" => _trigger_id,
        "type" => "view_submission",
        "view" => %{
          "callback_id" => "enable_view",
          "state" => %{
            "values" => values
          }
        }
      }) do
    case parse_state_values(Map.values(values)) do
      %{
        channel_id: "invalid",
        name: _
      } ->
        :invalid

      %{
        channel_id: channel_id,
        name: name
      } ->
        Channels.create_or_update_channel(channel_id, %{
          name: name,
          disabled: false
        })

        :ok
    end
  end

  defp parse_state_values(values) do
    with [
           %{
             "channel_select" => %{
               "selected_option" => %{
                 "text" => name,
                 "value" => channel_id
               },
               "type" => "static_select"
             }
           }
         ] <- values do
      Map.new(%{
        name: name["text"],
        channel_id: channel_id
      })
    end
  end

  defp build_disable_view(%{trigger_id: trigger_id}) do
    slack_channels =
      Enum.map(Slack.get_channels(%{trigger_id: trigger_id}), fn channel ->
        %{channel_id: channel["id"], name: channel["name"], disabled: false}
      end)

    all_channels = Channels.get_all() ++ slack_channels

    enabled_channels =
      all_channels
      |> Enum.uniq_by(fn channel -> channel.channel_id end)
      |> Enum.reject(fn channel -> channel.disabled end)

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
              Enum.map(enabled_channels, fn channel ->
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
    channels =
      case Channels.get_disabled() do
        [] ->
          [%{name: "There are no disabled channels", channel_id: "invalid"}]

        channels ->
          channels
      end

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
