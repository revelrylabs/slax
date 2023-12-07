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

  test "creates or updates a channel to be disabled", %{channel_id: channel_id, values: values} do
    event = %{
      "trigger_id" => "trigger_id",
      "type" => "view_submission",
      "view" => %{
        "callback_id" => "disable_view",
        "state" => %{
          "values" => values
        }
      }
    }

    assert :ok == Disable.handle_payload(event)
    assert Channels.disabled?(channel_id) == true
  end

  test "creates or updates a channel to be enabled", %{channel_id: channel_id, values: values} do
    event = %{
      "trigger_id" => "trigger_id",
      "type" => "view_submission",
      "view" => %{
        "callback_id" => "enable_view",
        "state" => %{
          "values" => values
        }
      }
    }

    assert :ok == Disable.handle_payload(event)
    assert Channels.disabled?(channel_id) == false
  end
end
