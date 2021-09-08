defmodule Slax.Shoutouts.InsertShoutout do
  @moduledoc """
  Defines a function to insert a shoutout into the database.
  """

  alias Slax.Repo
  alias Slax.Schemas.Shoutout
  alias Slax.Schemas.ShoutoutReceiver
  alias Slax.Schemas.User
  alias Slax.Slack.Announce
  alias Slax.Teams
  alias Slax.Users

  alias Ecto.Multi

  @doc false
  def insert_shoutout(attrs) do
    Multi.new()
    |> Multi.put(:attrs, attrs)
    |> Multi.put(:team, Teams.get_team(slack_id: attrs.slack_team_id))
    |> Multi.insert_or_update(:sender, &insert_or_update_user/1)
    |> Multi.insert(:shoutout, &shoutout_changeset/1)
    |> Multi.merge(&add_users/1)
    |> Multi.run(:announce, &announce/2)
    |> Multi.run(:update_dashboard, &update_dashboard/2)
    |> Repo.transaction()
  end

  defp announce(_, %{shoutout: shoutout} = changes) do
    user_ids =
      changes
      |> Map.values()
      |> Enum.filter(&is_user/1)
      |> Enum.map(& &1.id)

    %{user_ids: user_ids, shoutout_id: shoutout.id}
    |> Announce.new()
    |> Oban.insert()
  end

  defp update_dashboard(_, %{shoutout: shoutout, team: team}) do
    {:ok,
     Phoenix.PubSub.broadcast(
       Slax.PubSub,
       "new_shoutout_for_team_#{team.id}",
       {:update, shoutout}
     )}
  end

  defp insert_or_update_user(%{attrs: %{slack_sender_id: slack_sender_id}}) do
    user = Users.get_user(slack_id: slack_sender_id) || %User{}
    User.changeset(user, %{slack_id: slack_sender_id})
  end

  defp shoutout_changeset(%{team: team, sender: sender, attrs: attrs}) do
    Shoutout.changeset(%Shoutout{sender_id: sender.id, team_id: team.id}, attrs)
  end

  defp add_users(%{shoutout: shoutout, attrs: %{slack_receiver_ids: slack_receiver_ids}}) do
    slack_receiver_ids
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {slack_sender_id, index}, multi ->
      insert_user_step = String.to_atom("insert_user_#{index}")
      insert_users_shoutout_step = String.to_atom("insert_users_shoutout_#{index}")

      multi
      |> Multi.insert_or_update(insert_user_step, fn _changes ->
        user = Users.get_user(slack_id: slack_sender_id) || %User{}
        User.changeset(user, %{slack_id: slack_sender_id})
      end)
      |> Multi.insert(insert_users_shoutout_step, fn changes ->
        user = Map.get(changes, insert_user_step)

        Ecto.Changeset.change(%ShoutoutReceiver{}, %{
          shoutout_id: shoutout.id,
          user_id: user.id
        })
      end)
    end)
  end

  defp is_user(%User{}), do: true
  defp is_user(_), do: false
end
