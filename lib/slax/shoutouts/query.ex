defmodule Slax.Shoutouts.Query do
  @moduledoc """
  Defines the query API for accessing the Shoutouts.
  """

  import Ecto.Query

  alias Slax.Repo
  alias Slax.Schemas.Shoutout
  alias Slax.Schemas.ShoutoutReceiver

  @doc false
  def get_shoutout(params \\ []) when is_list(params) do
    params
    |> query_shoutouts()
    |> default_preloads()
    |> default_order()
    |> Repo.one()
  end

  @doc false
  def list_shoutouts(params \\ []) when is_list(params) do
    params
    |> query_shoutouts()
    |> default_preloads()
    |> default_order()
    |> Repo.all()
  end

  @doc false
  def page_shoutouts(query_params, page_params) do
    query_params
    |> query_shoutouts()
    |> default_preloads()
    |> default_order()
    |> Repo.paginate(page_params)
  end

  @doc false
  def count_shoutouts(params) do
    params
    |> query_shoutouts()
    |> select([s], count(s.id))
    |> Repo.one()
  end

  defp query_shoutouts(params) do
    apply_filters(Shoutout, params)
  end

  defp default_preloads(query) do
    preload(query, [:team, :sender, :receivers])
  end

  defp default_order(query) do
    order_by(query, [s], desc: s.inserted_at)
  end

  defp filter(query, {:id, id}) do
    where(query, id: ^id)
  end

  defp filter(query, {:receiver, user_id}) do
    query
    |> join(:left, [s], sr in ShoutoutReceiver, on: s.id == sr.shoutout_id, as: :sr)
    |> where([sr: sr], sr.user_id == ^user_id)
  end

  defp filter(query, {:team_id, team_id}) do
    where(query, [s], s.team_id == ^team_id)
  end

  defp filter(query, {:sender_id, sender_id}) do
    where(query, [s], s.sender_id == ^sender_id)
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
