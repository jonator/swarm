defmodule SwarmWeb.Auth.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :swarm,
    module: SwarmWeb.Auth.Guardian,
    error_handler: SwarmWeb.Auth.ErrorHandler

  @claims %{iss: "swarm"}

  plug Guardian.Plug.VerifySession, claims: @claims
  plug Guardian.Plug.VerifyHeader, claims: @claims, scheme: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end
