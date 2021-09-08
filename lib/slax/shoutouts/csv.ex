defmodule Slax.Shoutouts.CSV do
  @moduledoc """
  Provides a function for exporting shoutouts to CSV.
  """

  import Ecto.Query

  alias Slax.Repo
  alias Slax.Schemas.Shoutout
  alias Slax.Schemas.ShoutoutReceiver
  alias Slax.Schemas.User

  NimbleCSV.define(CSVParser, separator: ",", escape: "\"")

  @headers [
    [
      "DateTime",
      "Sender",
      "Sender Slack Id",
      "Receiver",
      "Receiver Slack Id",
      "Message"
    ]
  ]

  @spec stream_csv(Plug.Conn.t(), team_id :: integer()) ::
          {:ok, Plug.Conn.t()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def stream_csv(conn, team_id) do
    conn = build_conn(conn)

    Repo.transaction(fn ->
      team_id
      |> query()
      |> Repo.stream()
      |> (&Stream.concat(@headers, &1)).()
      |> CSVParser.dump_to_stream()
      |> Enum.reduce_while(conn, &send_to_conn(&2, &1))
    end)
  end

  defp build_conn(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/csv")
    |> Plug.Conn.put_resp_header(
      "content-disposition",
      "attachment; filename=\"shoutouts.csv\""
    )
    |> Plug.Conn.send_chunked(200)
  end

  defp query(team_id) do
    Shoutout
    |> where([s], s.team_id == ^team_id)
    |> join(:right, [s], sr in ShoutoutReceiver, on: s.id == sr.shoutout_id, as: :sr)
    |> join(:left, [sr: sr], u in User, on: sr.user_id == u.id, as: :receiver)
    |> join(:left, [s], u in User, on: s.sender_id == u.id, as: :sender)
    |> select([s, receiver: receiver, sender: sender], [
      s.inserted_at,
      sender.name,
      sender.slack_id,
      receiver.name,
      receiver.slack_id,
      s.message
    ])
  end

  defp send_to_conn(conn, data) do
    case Plug.Conn.chunk(conn, data) do
      {:ok, conn} ->
        {:cont, conn}

      {:error, :closed} ->
        {:halt, conn}
    end
  end
end
