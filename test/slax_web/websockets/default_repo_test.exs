defmodule SlaxWeb.DefaultRepo.Test do
  use SlaxWeb.ConnCase, async: true

  import Mox
  alias SlaxWeb.DefaultRepo

  setup do
    %{channel_id: channel_id} = insert(:channel, channel_id: "ABCDEFG")
    repo = insert(:project_repo)

    values = %{
    "abcdefg" => %{
      "repo_select" => %{"selected_option" => %{"value" => repo}},
      "channels_select_action" => %{"selected_channel" => channel_id},
        "type" => "static_select"
      }
    }

    [channel_id: channel_id, values: values]
  end

  test "sets default repo", %{channel_id: channel_id, values: values} do
    # WIP - channels list needs to be parseable
    expect(
      Slax.HttpMock,
      :get,
      fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"ok": true, "channels": #{List.to_string([id: "ABCDEFG"])}}>}} end
    )

    event = %{
      "trigger_id" => "123",
      "type" => "view_submission",
      "view" => %{
        "callback_id" => "default_repo_view",
        "state" => %{
          "values" => values
        }
      }
    }

    assert :ok == DefaultRepo.handle_payload(event)

    %{channel_id: test} = Slax.Channels.maybe_get_default_repo(channel_id)
    assert channel_id == test
  end
end
