defmodule Slax.Poker.Estimates do
  use Slax.Context
  alias Slax.Poker.Estimate

  @valid_estimates [1, 2, 3, 5, 8, 13, 666]

  def validate_estimate(estimate) do
    valid = Enum.member?(@valid_estimates, estimate)

    case valid do
      true -> {:ok, "Recorded, your estimate is #{estimate}."}
      _ -> {:error, "Valid estimates are [1, 2, 3, 5, 8, 13, 666]"}
    end
  end

  def create_or_update_estimate(round_id, %{user: user} = attrs) do
    case Repo.get_by(Estimate, %{round_id: round_id, user: user}) do
      nil -> %Estimate{round_id: round_id}
      estimate -> estimate
    end
    |> Estimate.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
