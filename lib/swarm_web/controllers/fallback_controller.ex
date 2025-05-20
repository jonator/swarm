defmodule SwarmWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use SwarmWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: SwarmWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: SwarmWeb.ErrorHTML, json: SwarmWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:unauthorized, reason}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{message: "Unauthorized #{reason}"})
  end

  # Handles all other errors from error tuple pattern
  def call(conn, {:error, message}) do
    conn
    |> put_status(500)
    |> json(%{message: message})
  end

  # Handles errors from Tentacat client
  def call(conn, {status, %{"message" => message}, _http_poison_resp}) do
    conn
    |> put_status(status)
    |> json(%{message: message})
  end
end
