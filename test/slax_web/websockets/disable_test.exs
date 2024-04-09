defmodule SlaxWeb.Disable.Test do
  use SlaxWeb.ConnCase, async: true

  alias SlaxWeb.Disable
  alias Slax.Channels

  setup do
    channel_id = "ABCDEFG"

    values = %{
      "abcdefg" => %{
        "channel_select" => %{
          "selected_option" => %{
            "text" => %{"emoji" => true, "text" => "test", "type" => "plain_text"},
            "value" => channel_id
          },
          "type" => "static_select"
        }
      }
    }

    [channel_id: channel_id, values: values]
  end

  test "updates a channel to be enabled", %{channel_id: channel_id, values: values} do
    event = %{
      "type" => "view_submission",
      "view" => %{
        "callback_id" => "enable_view",
        "state" => %{
          "values" => values
        }
      }
    }

    assert %{title: %{text: "Confirmation"}} = Disable.handle_payload(event)
    assert Channels.get_by_channel_id(channel_id).disabled == false
  end
end
