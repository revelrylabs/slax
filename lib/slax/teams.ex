defmodule Slax.Teams do
  @moduledoc """
  Context module for fetching %Slax.Schema.Team{}
  """

  alias Slax.Repo
  alias Slax.Schemas.Team
  alias Slax.Teams.Delete
  alias Slax.Teams.Query

  @typep params :: {:id, integer()} | {:slack_id, binary()} | {:user_id, integer()}

  @spec get_team([params()]) :: Team.t()
  defdelegate get_team(params), to: Query

  @spec list_teams([params()]) :: [Team.t()]
  defdelegate list_teams(params), to: Query

  @doc """
  Delete a team by id.
  """
  @spec delete_team(id :: integer()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  defdelegate delete_team(team_id), to: Delete

  @doc """
  Updates a team with the default changeset.
  """
  @spec update_team(team :: Team.t(), attrs :: map()) ::
          {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def update_team(team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end
end
