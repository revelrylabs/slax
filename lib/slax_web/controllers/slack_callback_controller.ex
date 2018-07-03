defmodule SlaxWeb.SlackCallbackController do
  @moduledoc """
  This controller handles incoming callbacks from Slack for interactive messages
  """
  use SlaxWeb, :controller

  # plug(Slax.Plugs.VerifyToken)

  def start(conn, %{"payload" => payload}) do
    payload
    |> Poison.decode!()
    |> handle_callback()

    text conn, ""
  end

  # Sprint commitment callbacks

  def handle_callback(%{"callback_id" => "sprint_commitment", "actions" => [%{"value" => "cancel"}|_]} = params) do
    Slax.Slack.send_message(params["response_url"], %{
      text: "Commitment canceled."
    })
  end

  def handle_callback(%{"callback_id" => "sprint_commitment", "actions" => [%{"value" => sprint_id}|_]} = params) do
    sprint = Slax.Sprints.get_sprint(sprint_id)

    Slax.Sprints.ConfirmCommitmentSaga.confirm_sprint_commitment(%{
      sprint: sprint,
      response_url: params["response_url"],
      callback_params: params,
    })
  end

  # Catch-all callback

  def handle_callback(_) do
    nil
  end
end
