defmodule Swarm.Repo do
  use Ecto.Repo,
    otp_app: :swarm,
    adapter: Ecto.Adapters.Postgres
end
