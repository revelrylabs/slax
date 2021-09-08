defmodule Slax.TeamFactory do
  defmacro __using__(_opts) do
    quote do
      def team_factory do
        %Slax.Schemas.Team{
          name: sequence(:team_name, &"name-#{&1}"),
          slack_id: sequence(:slack_id, &"slack_id-#{&1}"),
          token: sequence(:team_token, &"token-#{&1}")
        }
      end

      def with_user(team) do
        user = insert(:user)
        insert(:users_team, user: user, team: team)
        %{team: team, user: user}
      end
    end
  end
end
