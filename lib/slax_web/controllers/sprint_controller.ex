defmodule SlaxWeb.SprintController do
  use SlaxWeb, :controller

  plug(Slax.Plugs.VerifySlackToken, token: :sprint)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.{Projects, Sprints}

  def start(conn, %{"channel_name" => channel_name, "text" => "commitment " <> issue_numbers}) do
    case Regex.scan(~r/\d+/, issue_numbers) do
      [] ->
        text(conn, "Invalid issue numbers.")

      issue_numbers ->
        issue_numbers =
          issue_numbers
          |> List.flatten()
          |> Enum.map(&String.to_integer/1)

        case Projects.get_project_for_channel(channel_name) do
          nil ->
            text(conn, "A project could not be found for this channel.")

          project ->
            repo = List.first(project.repos)

            {_year, week} = :calendar.iso_week_number()

            maybe_handle_sprint_commitment_errors(
              %{
                repo: repo,
                issue_numbers: issue_numbers,
                week: week,
                user: conn.assigns.current_user
              },
              conn
            )
        end
    end
  end

  def start(conn, _) do
    text(conn, """
    *Sprint commands:*
    /sprint commitment <issue numbers separated by spaces> - Create a new sprint commitment
    """)
  end

  defp maybe_handle_sprint_commitment_errors(params, conn) do
    case Sprints.create_sprint_commitment(params) do
      {:error, messages, _} ->
        text(conn, Enum.join(messages, "\n"))

      {:ok, _, _} ->
        text(conn, "Sprint commitment set for week #{params[:week]}.")
    end
  end
end
