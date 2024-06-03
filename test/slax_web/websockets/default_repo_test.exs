defmodule SlaxWeb.DefaultRepo.Test do
  use SlaxWeb.ConnCase, async: true

  import Mox
  alias SlaxWeb.DefaultRepo

  setup do
    channel_id = "CHANNEL_ID"

    %{
      default_project_repo: default_project_repo
    } =
      insert(
        :channel,
        channel_id: channel_id,
        name: "CHANNEL_NAME",
        default_project_repo: build(:project_repo)
      )

    repo = insert(:project_repo)

    values = %{
      "channel_id" => %{
        "repo_select" => %{"selected_option" => %{"value" => repo.id}},
        "channels_select_action" => %{"selected_channel" => channel_id},
        "type" => "static_select"
      }
    }

    [
      channel_id: channel_id,
      values: values,
      default_project_repo: default_project_repo
    ]
  end

  test "sets default repo", %{channel_id: channel_id, values: values} do
    %{id: initial_default_project_repo_id} = Slax.Channels.maybe_get_default_repo(channel_id)

    expect(
      Slax.HttpMock,
      :get,
      fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"ok": true, "channels": [{"id": "CHANNEL_ID", "name": "CHANNEL_NAME"}]}>
         }}
      end
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

    %{id: new_default_project_repo_id} = Slax.Channels.maybe_get_default_repo(channel_id)

    assert new_default_project_repo_id != initial_default_project_repo_id
  end
end
