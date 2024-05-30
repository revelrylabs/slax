defmodule Slax.Channels.Test do
  use Slax.ModelCase, async: true
  alias Slax.{Channels}

  setup do
    default_repo = insert(:project_repo)
    other_repo = insert(:project_repo)
    channel = insert(:channel, default_project_repo: default_repo)

    [default_repo: default_repo, channel: channel, other_repo: other_repo]
  end

  describe "get default repo for channel" do
    test "maybe_get_default_repo/1", %{default_repo: default_repo, channel: channel} do

      repo = Channels.maybe_get_default_repo(channel.channel_id)

      assert repo.id == default_repo.id
    end

    test "set_default_repo/1", %{default_repo: _, channel: channel, other_repo: other_repo} do
      Channels.set_default_repo(%{"id" => channel.channel_id, "name" => channel.name}, %{default_project_repo_id: other_repo.id})

      repo = Channels.maybe_get_default_repo(channel.channel_id)

      assert repo.id == other_repo.id
    end
  end
end
