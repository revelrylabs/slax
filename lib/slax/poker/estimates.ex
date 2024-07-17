defmodule Slax.Poker.Estimates do
  @moduledoc false
  use Slax.Context
  alias Slax.Poker.Estimate

  @valid_estimates [1, 2, 3, 5, 8, 13, 666]

  def validate_estimate(estimate) do
    @valid_estimates
    |> Enum.member?(estimate)
    |> case do
      true -> :ok
      _ -> {:error, "Valid estimates are [1, 2, 3, 5, 8, 13, 666]"}
    end
  end

  def create_or_update_estimate(round_id, %{user: user} = attrs) do
    estimate =
      case Repo.get_by(Estimate, %{round_id: round_id, user: user}) do
        nil -> %Estimate{round_id: round_id}
        estimate -> estimate
      end

    estimate
    |> Estimate.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
