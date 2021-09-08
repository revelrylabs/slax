defmodule Slax.ShoutoutFactory do
  defmacro __using__(_opts) do
    quote do
      def shoutout_factory do
        %Slax.Schemas.Shoutout{
          message: sequence(:message, &"name-#{&1}"),
          team: build(:team),
          sender: build(:user),
        }
      end

      def with_receivers(shoutout) do
        [user1, user2] = insert_pair(:user)
        insert(:users_team, user: user1, team: shoutout.team)
        insert(:users_team, user: user2, team: shoutout.team)
        %{shoutout | receivers: [user1, user2]}
      end
    end
  end
end
