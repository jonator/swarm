defmodule Swarm do
  @moduledoc """
  Swarm Application Context Module

  This module serves as the main entry point for the Swarm application,
  which provides AI-powered development assistance through automated agents.

  ## Overview

  Swarm is a system that:
  - Integrates with Linear and GitHub to handle development tasks
  - Spawns AI agents to implement code changes and manage repositories
  - Provides a web interface for monitoring and managing agents
  - Handles user authentication and organization management

  ## Architecture

  The application is organized into several key contexts:

  - **Accounts**: User management and authentication
  - **Organizations**: Multi-tenant organization structure
  - **Repositories**: Git repository management and integration
  - **Projects**: Project-specific configuration and settings
  - **Agents**: AI agent lifecycle and execution management
  - **Ingress**: Webhook handling and event processing
  - **Egress**: External API integrations (Linear, GitHub)
  - **Tools**: Agent capabilities and tool definitions
  - **Workers**: Background job processing for agents

  ## Data Flow

  1. External events (Linear issues, GitHub PRs) trigger webhooks
  2. Ingress handlers process events and create agent tasks
  3. Workers execute agent tasks using appropriate tools
  4. Agents interact with repositories and external services
  5. Results are communicated back through egress handlers

  ## Usage

  This module primarily serves as a namespace and documentation hub.
  Individual functionality is implemented in the respective context modules.

  For specific operations, see:
  - `Swarm.Accounts` for user management
  - `Swarm.Agents` for agent operations
  - `Swarm.Repositories` for repository management
  - `Swarm.Workers.Coder` for code implementation tasks
  - `Swarm.Workers.Researcher` for research and analysis tasks
  """

  @doc """
  Returns the current version of the Swarm application.
  """
  @spec version() :: binary()
  def version do
    Application.spec(:swarm, :vsn) |> to_string()
  end

  @doc """
  Returns basic application information.
  """
  @spec info() :: map()
  def info do
    %{
      name: "Swarm",
      version: version(),
      description: "AI-powered development assistance platform",
      environment: Application.get_env(:swarm, :environment, :dev)
    }
  end
end