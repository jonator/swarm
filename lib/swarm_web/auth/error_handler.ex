defmodule SwarmWeb.Auth.ErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body =
      Jason.encode!(%{
        error: error_message(type)
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(error_status(type), body)
    |> halt()
  end

  defp error_status(:unauthenticated), do: :unauthorized
  defp error_status(:invalid_token), do: :unauthorized
  defp error_status(:already_authenticated), do: :forbidden
  defp error_status(:no_resource_found), do: :unauthorized
  defp error_status(_), do: :forbidden

  defp error_message(:unauthenticated), do: "You must be signed in to access this resource."
  defp error_message(:invalid_token), do: "Authentication token is invalid."
  defp error_message(:already_authenticated), do: "You're already authenticated."
  defp error_message(:no_resource_found), do: "User account not found."
  defp error_message(_), do: "Authentication error."
end
