defmodule SwarmWeb.EventController do
  use SwarmWeb, :controller

  def receive_event(conn, params) do
    # TODO: Implement event handling logic

    IO.inspect(params)

    conn
    |> put_status(:ok)
    |> json(%{status: "received"})
  end
end
