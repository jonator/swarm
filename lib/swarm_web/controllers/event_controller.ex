defmodule SwarmWeb.EventController do
  use SwarmWeb, :controller

  alias Swarm.Ingress.Verify

  require Logger

  def create(conn, _params) do
    # Get the raw body from assigns (set by CacheBodyReader)
    [raw_body | _] = conn.assigns[:raw_body] || [""]
    event_data = conn.body_params
    source = determine_event_source(conn, event_data)
    headers = Enum.into(conn.req_headers, %{})
    remote_ip = :inet_parse.ntoa(conn.remote_ip) |> to_string()

    # Write event data to tmp directory for debugging
    tmp_dir = Path.join(System.tmp_dir!(), "swarm_events")
    File.mkdir_p!(tmp_dir)

    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    filename = "#{source}_#{timestamp}.json"
    filepath = Path.join(tmp_dir, filename)

    File.write!(filepath, Jason.encode!(event_data, pretty: true))
    Logger.info("Event data written to: #{filepath}")

    case Verify.verify(raw_body, event_data, headers, remote_ip, source) do
      :ok ->
        case Swarm.Ingress.process_event(event_data, source) do
          {:ok, agent, job} ->
            json(conn, %{
              status: "agent_created",
              agent_id: agent.id,
              agent_name: agent.name,
              agent_type: agent.type,
              job_id: job.id
            })

          {:ok, :updated} ->
            conn
            |> put_status(:ok)
            |> json(%{status: "agent_updated", message: "Existing agent updated"})

          {:ok, :ignored} ->
            json(conn, %{status: "ignored", message: "Event was ignored"})

          {:error, reason} ->
            Logger.error("Error processing event: #{reason}")

            conn
            |> put_status(:unprocessable_entity)
            |> json(%{status: "error", message: reason})
        end

      {:error, reason} ->
        Logger.error("Error verifying event: #{reason}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", message: reason})
    end
  end

  defp determine_event_source(conn, params) do
    cond do
      get_req_header(conn, "x-github-event") != [] or
          (Map.has_key?(params, "repository") and Map.has_key?(params, "sender")) ->
        :github

      get_req_header(conn, "linear-event") != [] or
          (Map.has_key?(params, "data") and Map.has_key?(params, "action")) ->
        :linear

      get_req_header(conn, "x-slack-signature") != [] or
          (Map.has_key?(params, "event") and Map.has_key?(params, "team_id")) ->
        :slack

      params["source"] == "manual" ->
        :manual

      true ->
        :unknown
    end
  end
end
