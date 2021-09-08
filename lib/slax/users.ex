defmodule Slax.Users do
  @moduledoc """
  Context module for fetching %Slax.Schema.User{}
  """
  alias Slax.Users.Query

  @typep params :: {:id, integer()} | {:slack_id, binary()} | {:slack_ids, [binary()]}

  @spec get_user([params()]) :: User.t()
  defdelegate get_user(params), to: Query

  @spec list_users([params()]) :: [User.t()]
  defdelegate list_users(params), to: Query
end
