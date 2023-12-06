defmodule SlaxWeb.Disable do
  @moduledoc """
  A module that handles Slack websocket payloads for disabling Slax interactions and
  builds modal views for slack https://api.slack.com/reference/surfaces/views
  """

  alias Slax.Slack

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "shortcut",
        "callback_id" => "disable_slax"
      }) do
    view = build_disable_view(%{trigger_id: trigger_id})

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
           "channel_select" => %{"selected_option" => channel}
         } <-
           parse_state_values(values) do
      IO.inspect(values, label: "HHHHHEHEHEHEHEHELLLLLOOOOOO")
      channel["value"] <> "x"
      :ok
    end
  end

  defp parse_state_values(values) do
    values
    |> Map.values()
    |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)
  end

  defp build_disable_view(%{trigger_id: trigger_id}) do
    channels =
      case Slack.get_channels(%{trigger_id: trigger_id}) do
        [] ->
          [%{name: "example", id: "example"}]

        channels ->
          channels
      end

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
                %{text: %{type: "plain_text", text: channel["name"]}, value: "#{channel["id"]}"}
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
