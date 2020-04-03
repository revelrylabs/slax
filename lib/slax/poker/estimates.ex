defmodule Slax.Estimates do
  use Slax.Context
  alias Slax.Estimate

  @valid_estimates [1, 2, 3, 5, 8, 13, 666]

  def validate_estimate(estimate, reason) do
    valid = Enum.member?(@valid_estimates, estimate)

    case valid do
      true -> {:ok, "Your value is #{estimate}, your reason is #{reason}."}
      _ -> {:error, "Valid estimates are [1, 2, 3, 5, 8, 13, 666]"}
    end
  end

  def register_estimate(user, estimate, reason, round_id) do
    %Estimate{}
    |> Estimate.changeset(%{
      user: user,
      value: estimate,
      reason: reason,
      round_id: round_id
    })
    |> Repo.insert()
  end
end
