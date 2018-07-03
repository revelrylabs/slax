defmodule SlaxWeb.SprintController do
  use SlaxWeb, :controller

  plug(Slax.Plugs.VerifySlackToken, :sprint)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Sprints

  def start(conn, %{"channel_name" => "directmessage"}) do
    text conn, "This must be called in a project channel to associate the sprint with a repo"
  end

  # This will start the commitment process by providing the user with details
  # about the issues provided (number and total score) and give them the
  # option to confirm the commitment or cancel the request
  def start(conn, %{
        "channel_name" => channel_name,
        "text" => "commitment " <> commitment_params,
        "response_url" => response_url
      }) do
    [issue_numbers, additional_message] =
      extract_issue_numbers_and_additional_message(commitment_params)

    Task.start(fn ->
      Sprints.CreateCommitmentSaga.find_or_create_current_commitment(%{
        issue_numbers: issue_numbers,
        additional_message: additional_message,
        channel_name: channel_name,
        current_user: conn.assigns.current_user,
        response_url: response_url
      })
    end)

    text(conn, "")
  end

  def start(conn, _) do
    text(conn, """
    *Sprint commands:*
    /sprint commitment <issue numbers separated by spaces> - Create a new sprint commitment
    """)
  end

  # Split the message by newlines into 2 parts to get the issue numbers and
  # an optional message for sprint goals. Then turn the issue numbers into
  # integers
  def extract_issue_numbers_and_additional_message(params) do
    params
    |> String.split("\n", parts: 2, trim: true)
    |> case do
      [_, _] = good_params -> good_params
      [issue_numbers] -> [issue_numbers, nil]
      [] -> ["", nil]
    end
    |> List.update_at(0, fn issue_numbers ->
      Regex.scan(~r/\d+/, issue_numbers)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)
    end)
  end
end
