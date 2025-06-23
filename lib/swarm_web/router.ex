defmodule SwarmWeb.Router do
  use SwarmWeb, :router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug SwarmWeb.Auth.AuthPipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :ensure_admin do
    plug Guardian.Permissions, ensure: %{default: [:admin]}
  end

  scope "/events", SwarmWeb do
    pipe_through [:api]

    post "/", EventController, :receive_event
  end

  scope "/api", SwarmWeb do
    pipe_through [:api, :auth]

    post "/auth/github", SessionController, :github

    # Auth
    scope "/auth" do
      pipe_through [:ensure_auth]
      post "/linear", LinearController, :exchange_code
      get "/linear", LinearController, :has_access
      get "/token", SessionController, :token
    end

    # Users
    scope "/users" do
      pipe_through [:ensure_auth]
      get "/", UserController, :show
      get "/:id", UserController, :show
    end

    # Repositories
    scope "/repositories" do
      pipe_through [:ensure_auth]
      resources "/", RepositoryController, only: [:index, :show, :create, :update]
    end

    # Organizations
    scope "/organizations" do
      pipe_through [:ensure_auth]
      resources "/", OrganizationController, only: [:index, :create, :update]
    end

    # GitHub
    scope "/github" do
      pipe_through [:ensure_auth]
      get "/installations", GitHubController, :installations
      get "/repositories", GitHubController, :repositories
      get "/repositories/git/trees", GitHubController, :trees
      get "/repositories/frameworks", GitHubController, :frameworks
    end

    # Linear
    scope "/linear" do
      pipe_through [:ensure_auth]
      get "/organization", LinearController, :organization
    end

    # Agents
    scope "/agents" do
      pipe_through [:ensure_auth]
      post "/spawn", EventController, :spawn_agent
      get "/", AgentController, :index
    end

    scope "/admin" do
      pipe_through [:ensure_auth, :ensure_admin]
      resources "/users", UserController
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:swarm, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SwarmWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview

      oban_dashboard("/oban")
    end
  else
    scope "/admin", SwarmWeb do
      pipe_through [:browser, :auth, :ensure_auth, :ensure_admin]

      oban_dashboard("/oban")
    end
  end
end
