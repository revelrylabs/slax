defmodule Slax.Teams.DeleteTest do
  @moduledoc false
  use Slax.DataCase

  alias Slax.Teams.Delete

  test "something" do
    %{team_id: team_id} = insert(:shoutout) |> with_receivers()
    assert {:ok, _} = Delete.delete_team(team_id)
  end
end
