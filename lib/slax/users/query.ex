defmodule Slax.Users.Query do
  @moduledoc """
  Defines the query API for accessing the Users.
  """

  import Ecto.Query

  alias Slax.Repo
  alias Slax.Schemas.User
  alias Slax.Schemas.UsersTeam

  @query_users from(user in User)

  @doc false
  def get_user(params \\ []) when is_list(params) do
    @query_users
    |> apply_filters(params)
    |> preload([:teams])
    |> Repo.one()
  end

  @doc false
  def list_users(params \\ []) when is_list(params) do
    @query_users
    |> apply_filters(params)
    |> preload([:teams])
    |> Repo.all()
  end

  defp filter(query, {:orphans, true}) do
    query
    |> join(:left, [u], ut in UsersTeam, on: u.id == ut.user_id, as: :ut)
    |> where([ut: ut], is_nil(ut.id))
  end

  defp filter(query, {:slack_id, slack_id}) do
    where(query, slack_id: ^slack_id)
  end

  defp filter(query, {:slack_ids, slack_ids}) do
    where(query, [u], u.slack_id in ^slack_ids)
  end

  defp filter(query, {:id, id}) do
    where(query, id: ^id)
  end

  defp filter(_, param) do
    raise ArgumentError, "Invalid arguments: #{inspect(param)}"
  end

  defp apply_filters(query, params) do
    Enum.reduce(params, query, fn param, query ->
      filter(query, param)
    end)
  end
end
