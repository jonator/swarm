defmodule SwarmWeb.CacheBodyReader do
  @moduledoc """
  Reads and caches the raw request body for use in Plug.Parsers.
  """
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
