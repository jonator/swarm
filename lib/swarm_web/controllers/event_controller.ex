defmodule SwarmWeb.EventController do
  use SwarmWeb, :controller

  require Logger

  alias Swarm.Ingress

  @doc """
  Receives webhook events from external services and processes them through the ingress system.

  The controller determines the event source based on headers or payload structure,
  then delegates to the appropriate ingress handler.
  """
  def receive_event(conn, params) do
    Logger.info("Received webhook event: #{inspect(params, pretty: true)}")

    # tmp_file = Path.join(System.tmp_dir!(), "swarm_webhook_#{:rand.uniform(1_000_000)}.json")
    # File.write!(tmp_file, Jason.encode!(params, pretty: true))
    # Logger.info("Wrote webhook payload to #{tmp_file}")

    with {:ok, source} <- determine_event_source(conn, params) do
      case Ingress.process_event(params, source) do
        {:ok, agent, job, msg} ->
          conn
          |> put_status(:created)
          |> json(%{
            status: "agent_created",
            message: msg,
            agent_id: agent.id,
            agent_name: agent.name,
            agent_type: agent.type,
            job_id: job.id
          })

        {:ok, :updated} ->
          conn
          |> put_status(:accepted)
          |> json(%{
            status: "agent_updated",
            message: "Existing agent updated"
          })

        {:ok, :ignored} ->
          conn
          |> put_status(:ok)
          |> json(%{
            status: "ignored",
            message: "Event was ignored"
          })

        {:error, reason} ->
          Logger.error("Event processing failed: #{reason}")

          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            status: "error",
            message: reason
          })
      end
    else
      {:error, reason} ->
        Logger.error("Event processing failed: #{reason}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: reason
        })
    end
  end

  @doc """
  Handles manual agent spawn requests from the frontend.

  This endpoint allows authenticated users to directly request agent creation
  with specific parameters and context.
  """
  def spawn_agent(conn, params) do
    # This would be called from authenticated API endpoints
    # For now, it's a placeholder for future frontend integration

    Logger.info("Manual agent spawn request: #{inspect(params)}")

    current_user = Guardian.Plug.current_resource(conn)
    user_id = current_user && current_user.id

    opts = [user_id: user_id]

    case Ingress.process_event(params, :manual, opts) do
      {:ok, agent, job, msg} ->
        conn
        |> put_status(:created)
        |> json(%{
          status: "agent_created",
          message: msg,
          agent_id: agent.id,
          agent_name: agent.name,
          agent_type: agent.type,
          job_id: job.id
        })

      {:ok, :updated} ->
        conn
        |> put_status(:accepted)
        |> json(%{
          status: "agent_updated",
          message: "Existing agent updated"
        })

      {:ok, :ignored} ->
        conn
        |> put_status(:ok)
        |> json(%{
          status: "ignored",
          message: "Request was ignored"
        })

      {:error, reason} ->
        Logger.error("Manual agent spawn failed: #{reason}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: reason
        })
    end
  end

  # Determines the event source based on request headers and payload structure.
  #
  # Different services send webhooks with different signatures and structures:
  # - GitHub: X-GitHub-Event header
  # - Linear: Linear-Event header
  # - Slack: Slack-Signature header
  defp determine_event_source(conn, params) do
    cond do
      # GitHub webhooks include X-GitHub-Event header
      get_req_header(conn, "x-github-event") != [] ->
        {:ok, :github}

      # Linear webhooks include specific structure or headers
      get_req_header(conn, "linear-event") != [] ->
        {:ok, :linear}

      # Slack webhooks include Slack-Signature header
      get_req_header(conn, "x-slack-signature") != [] ->
        {:ok, :slack}

      # Manual requests (would come through different endpoint typically)
      params["source"] == "manual" ->
        {:ok, :manual}

      # Try to infer from payload structure
      true ->
        infer_source_from_payload(params)
    end
  end

  defp infer_source_from_payload(params) do
    cond do
      # GitHub structure indicators
      Map.has_key?(params, "repository") and Map.has_key?(params, "sender") ->
        {:ok, :github}

      # Linear structure indicators
      Map.has_key?(params, "data") and Map.has_key?(params, "action") ->
        {:ok, :linear}

      # Slack structure indicators
      Map.has_key?(params, "event") and Map.has_key?(params, "team_id") ->
        {:ok, :slack}

      true ->
        {:error, "Unable to determine event source from headers or payload structure"}
    end
  end
end
