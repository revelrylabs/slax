defmodule SlaxWeb.PokerController do
  use SlaxWeb, :controller

  plug(Slax.Plugs.VerifySlackToken, token: :poker)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.{Github, Poker, Slack}
  alias Slax.Poker.Estimates
  alias Slax.Helpers.Text

  def start(conn, %{"text" => ""}) do
    text(conn, "
    *Poker commands:*
    /poker start [repo/123] -- _Start a new round of planning poker for issue 123 of the repo repo._

    /poker estimate [1|2|3|5|8|13] (reason) -- _Provide your complexity points for the current issue._

    /poker reveal -- _Reveal the estimates for the current issue._

    /poker decide [1|2|3|5|8|13] -- _Finalize the points for the current issue._

    /poker quit -- _Ends the current round of poker_
    ")
  end

  def start(conn, %{
        "text" => "start " <> repo_and_issue,
        "channel_name" => channel_name
      }) do
    with {:ok, issue} <- load_issue(repo_and_issue),
         {:ok, _} <- Poker.end_current_round_for_channel(channel_name),
         {:ok, response} <- Poker.start_round(channel_name, issue) do
      json(conn, %{
        response_type: "in_channel",
        text: response
      })
    else
      {:error, message} ->
        text(conn, message)

      other_error ->
        text(conn, "Something went wrong: #{inspect(other_error)}")
    end
  end

  def start(conn, %{
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
      has_have = if Enum.count(round.estimates) > 1, do: "have", else: "has"
      estimators = Enum.map(round.estimates, & &1.user) ++ [user]

      Slack.post_message_to_channel(
        "_#{Text.to_sentence(estimators)} #{has_have} estimated_",
        channel_name
      )

      text(conn, "Ok, your estimate for #{round.issue} is #{estimate}.")
    else
      {:error, message} ->
        text(conn, message)

      {:parse, :error} ->
        text(conn, "Could not parse estimate and/or reason")

      nil ->
        text(conn, "There isn't a round of poker for this channel")
    end
  end

  def start(conn, %{
        "channel_name" => channel_name,
        "text" => "reveal"
      }) do
    case Poker.get_current_round_for_channel(channel_name) do
      nil ->
        text(conn, "There doesn't seem to be a round active. Did you /poker start?")

      %{estimates: []} ->
        text(conn, "No one has estimated yet")

      round ->
        estimates = Enum.map(round.estimates, &"#{&1.user}=#{&1.value}")

        message = "Estimates for round: #{estimates}"

        message =
          if Enum.count(round.estimates, &(!is_nil(&1.reason))) > 0 do
            reasons = Enum.map(round.estimates, &"#{&1.user} (#{&1.value}): #{&1.reason}")
            "#{message}\n---\n#{Enum.join(reasons, "\n")}"
          else
            message
          end

        Slack.post_message_to_channel(message, channel_name)

        text(conn, "")
    end
  end

  def start(conn, %{"channel_name" => channel_name, "text" => "decide " <> score}) do
    with {:parse, {score, _}} <- {:parse, Integer.parse(score)},
         round = %Poker.Round{} <- Poker.get_current_round_for_channel(channel_name),
         :ok <- Poker.decide(round, score) do
      Slack.post_message_to_channel("Complexity of #{round.issue} is #{score}.", channel_name)

      text(conn, "")
    else
      {:parse, :error} ->
        text(conn, "Could not parse score")

      nil ->
        text(conn, "There doesn't seem to be a round active. Did you /poker start?")

      {:error, message} ->
        text(conn, message)
    end
  end

  def start(conn, %{"channel_name" => channel_name, "text" => "quit"}) do
    with round = %Poker.Round{} <- Poker.get_current_round_for_channel(channel_name),
         {:ok, _} <- Poker.end_current_round_for_channel(channel_name) do
      text(conn, "Poker closed for #{round.issue}")
    else
      {:error, message} ->
        text(conn, message)
    end
  end

  def start(conn, _) do
    text(conn, "Unknown command, try again")
  end

  defp load_issue(repo_and_issue) do
    repo_and_issue
    |> Github.parse_repo_org_issue()
    |> case do
      {org, repo, issue} ->
        client = Tentacat.Client.new(%{access_token: Github.api_token()})

        case Tentacat.Issues.find(client, org, repo, issue) do
          {200, issue, _http_response} ->
            {:ok, issue}

          {_response_code, %{"message" => error_message}, _http_response} ->
            {:error, error_message}
        end

      {:error, _message} = error ->
        error
    end
  end
end
