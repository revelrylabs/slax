defmodule Slax.Teams.Query do
  @moduledoc """
  Defines the query API for accessing the Teams.
  """

  import Ecto.Query

  alias Slax.Repo
  alias Slax.Schemas.Team

  @query_teams from(team in Team)

  @doc false
  def get_team(params \\ []) when is_list(params) do
    @query_teams
    |> apply_filters(params)
    |> Repo.one()
  end

  @doc false
  def list_teams(params \\ []) when is_list(params) do
    @query_teams
    |> apply_filters(params)
    |> Repo.all()
  end

  defp filter(query, {:id, id}) do
    where(query, id: ^id)
  end

  defp filter(query, {:slack_id, slack_id}) do
    where(query, slack_id: ^slack_id)
  end

  defp filter(query, {:user_id, user_id}) do
    query
    |> join(:left, [t], u in assoc(t, :users), as: :users)
    |> where([users: users], users.id == ^user_id)
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
