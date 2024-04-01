defmodule SlaxWeb.Poker do
  alias Slax.{Github, Poker, Slack}
  alias Slax.Poker.Estimates
  alias Slax.Helpers.Text

  def start(%{"text" => ""}) do
    %{text: "
    *Poker commands:*
    /poker start [repo/123] -- _Start a new round of planning poker for issue 123 of the repo repo._

    /poker estimate [1|2|3|5|8|13] (reason) -- _Provide your complexity points for the current issue._

    /poker reveal -- _Reveal the estimates for the current issue._

    /poker decide [1|2|3|5|8|13] -- _Finalize the points for the current issue._

    /poker quit -- _Ends the current round of poker_
    "}
  end

  def start(%{
        "text" => "start " <> repo_and_issue,
        "channel_name" => channel_name
      }) do
    with {:ok, issue, warning_message} <- Github.load_issue(repo_and_issue),
         {:ok, _} <- Poker.end_current_round_for_channel(channel_name),
         {:ok, response} <- Poker.start_round(channel_name, issue) do
      %{
        response_type: "in_channel",
        text: response <> warning_message
      }
    else
      {:error, message} ->
        %{text: message}

      other_error ->
        %{text: "Something went wrong: #{inspect(other_error)}"}
    end
  end

  def start(%{
        "user_name" => user,
        "channel_name" => channel_name,
        "text" => "estimate " <> estimate_and_reason
      }) do
    with {:parse, {estimate, reason}} <- {:parse, Integer.parse(estimate_and_reason)},
         :ok <- Estimates.validate_estimate(estimate),
         round = %Poker.Round{} <- Poker.get_current_round_for_channel(channel_name),
         {:ok, _response} <-
           Estimates.create_or_update_estimate(round.id, %{
             user: user,
             value: estimate,
             reason: reason
           }) do
      estimators = Enum.map(round.estimates, & &1.user) ++ [user]
      has_have = if Enum.count(estimators) > 1, do: "have", else: "has"

      Slack.post_message_to_channel(
        "_#{Text.to_sentence(estimators)} #{has_have} estimated_ (#{length(estimators)})",
        channel_name
      )

      %{text: "Ok, your estimate for #{round.issue} is #{estimate}."}
    else
      {:error, message} ->
        %{text: message}

      {:parse, :error} ->
        %{text: "Could not parse estimate and/or reason"}

      nil ->
        %{text: "There isn't a round of poker for this channel"}
    end
  end

  def start(%{
        "channel_name" => channel_name,
        "text" => "reveal"
      }) do
    case Poker.get_current_round_for_channel(channel_name) do
      nil ->
        %{text: "There doesn't seem to be a round active. Did you /poker start?"}

      %{estimates: []} ->
        %{text: "No one has estimated yet"}

      round ->
        estimates =
          round.estimates
          |> Enum.sort_by(& &1.value)
          |> Enum.map(&"#{&1.user} (#{&1.value})#{if &1.reason, do: ': #{&1.reason}'}")

        message = "Estimates for round:\n---\n#{Enum.join(estimates, "\n")}"

        Slack.post_message_to_channel(message, channel_name)

        %{}
    end
  end

  def start(%{"channel_name" => channel_name, "text" => "decide " <> score}) do
    with {:parse, {score, _}} <- {:parse, Integer.parse(score)},
         round = %Poker.Round{} <- Poker.get_current_round_for_channel(channel_name),
         :ok <- Poker.decide(round, score) do
      Slack.post_message_to_channel("Complexity of #{round.issue} is #{score}.", channel_name)

      %{}
    else
      {:parse, :error} ->
        %{text: "Could not parse score"}

      nil ->
        %{text: "There doesn't seem to be a round active. Did you /poker start?"}

      {:error, message} ->
        %{text: message}
    end
  end

  def start(%{"channel_name" => channel_name, "text" => "quit"}) do
    with round = %Poker.Round{} <- Poker.get_current_round_for_channel(channel_name),
         {:ok, _} <- Poker.end_current_round_for_channel(channel_name) do
      %{text: "Poker closed for #{round.issue}"}
    else
      {:error, message} ->
        %{text: message}
    end
  end

  def start(_, _) do
    %{text: "Unknown command, try again"}
  end
end
