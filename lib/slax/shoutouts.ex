defmodule Slax.Shoutouts do
  @moduledoc """
  Context module for shoutouts.
  """
  alias Slax.Shoutouts.InsertShoutout
  alias Slax.Shoutouts.Query

  @typep params ::
           {:id, integer()}
           | {:receiver, integer()}
           | {:team_id, integer()}
           | {:sender_id, integer()}

  @typep page_params :: %{optional(:page) => integer(), optional(:page_size) => integer()}

  @spec get_shoutout([params()]) :: Shoutout.t()
  defdelegate get_shoutout(params), to: Query

  @spec list_shoutouts([params()]) :: [Shoutout.t()]
  defdelegate list_shoutouts(params), to: Query

  @spec page_shoutouts([params()], page_params()) :: Scrivener.Page.t()
  defdelegate page_shoutouts(query_params, page_params), to: Query

  @spec count_shoutouts([params()]) :: integer()
  defdelegate count_shoutouts(params), to: Query

  @spec insert_shoutout(map()) ::
          {:ok, map()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  defdelegate insert_shoutout(attrs), to: InsertShoutout
end
