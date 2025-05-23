defmodule SwarmWeb.Auth.CurrentResource do
  @moduledoc """
  Use this module in a controller to take the advantage of having
  the subject of authentication (eg.: JWT current resource) injected
  in the action as the third argument.

  ## Options

  * `:required` - when true, automatically returns 401 Unauthorized if no current_resource is present (default: true)

  ## Usage example

  defmodule SwarmWeb.MyController do
    use SwarmWeb, :controller
    use SwarmWeb.CurrentResource, required: true

    plug Guardian.Plug.EnsureAuthenticated

    def index(conn, params, current_user) do
      # ..code..
    end
  end
  """
  defmacro __using__(opts \\ []) do
    required = Keyword.get(opts, :required, true)

    quote do
      def action(conn, _opts) do
        current_resource = Guardian.Plug.current_resource(conn)

        if unquote(required) && is_nil(current_resource) do
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Unauthorized"})
          |> halt()
        else
          apply(__MODULE__, action_name(conn), [
            conn,
            conn.params,
            current_resource
          ])
        end
      end
    end
  end
end
