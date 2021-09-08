defmodule SlaxWeb.ShoutoutController do
  use SlaxWeb, :controller

  require Logger

  alias Slax.Shoutouts

  def csv_download(conn, %{"team_id" => team_id}) do
    {:ok, conn} = Shoutouts.CSV.stream_csv(conn, team_id)

    conn
  end
end
