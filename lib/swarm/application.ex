defmodule Swarm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    flame_parent = FLAME.Parent.get()

    children =
      [
        SwarmWeb.Telemetry,
        Swarm.Repo,
        {DNSCluster, query: Application.get_env(:swarm, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Swarm.PubSub, pool_size: 4},
        {Finch, name: Swarm.Finch},
        !flame_parent && {Oban, Application.fetch_env!(:swarm, Oban)},
        {
          FLAME.Pool,
          # Run socat TCP-LISTEN:2375,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock & to expose docker API locally
          backend:
            {FLAME.DockerBackend,
             image: "swarmdev", env: %{"DOCKER_IP" => "host.docker.internal"}},
          name: Swarm.FlamePool,
          min: 0,
          max: 10,
          max_concurrency: 5,
          idle_shutdown_after: :timer.minutes(5),
          timeout: :timer.minutes(5),
          log: :debug
        },
        # Start to serve requests, typically the last entry
        !flame_parent && SwarmWeb.Endpoint
      ]
      |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Swarm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SwarmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
