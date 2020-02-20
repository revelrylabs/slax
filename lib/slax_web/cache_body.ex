defmodule SlaxWeb.CacheBodyReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.put_private(conn, :raw_body, body)
    {:ok, body, conn}
  end

  def read_cached_body(conn) do
    conn.private[:raw_body]
  end
end
