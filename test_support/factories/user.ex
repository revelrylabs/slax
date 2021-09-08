defmodule Slax.UserFactory do
  defmacro __using__(_opts) do
    quote do
      def user_factory do
        %Slax.Schemas.User{
          name: sequence(:user_name, &"name-#{&1}"),
          slack_id: sequence(:slack_id, &"slack_id-#{&1}"),
        }
      end
    end
  end
end
