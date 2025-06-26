defmodule Swarm.Ingress.Webhook do
  @moduledoc """
  Plug to verify webhook signatures for incoming /events requests.
  Reads the raw body and validates the signature before Plug.Parsers.
  """
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/events", method: "POST"} = conn, _opts) do
    case verify_resp_body(conn) do
      {:ok, :ok, _raw_body, decoded_body} ->
        source = determine_event_source(conn, decoded_body)

        case Swarm.Ingress.process_event(decoded_body, source) do
          {:ok, agent, job, msg} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              201,
              Jason.encode!(%{
                status: "agent_created",
                message: msg,
                agent_id: agent.id,
                agent_name: agent.name,
                agent_type: agent.type,
                job_id: job.id
              })
            )
            |> halt

          {:ok, :updated} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              202,
              Jason.encode!(%{
                status: "agent_updated",
                message: "Existing agent updated"
              })
            )
            |> halt

          {:ok, :ignored} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{
                status: "ignored",
                message: "Event was ignored"
              })
            )
            |> halt

          {:error, reason} ->
            Logger.error("Event processing failed: #{reason}")

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              422,
              Jason.encode!(%{
                status: "error",
                message: reason
              })
            )
            |> halt
        end

      {:ok, {:error, reason}, _raw_body, _decoded_body} ->
        Logger.error("Webhook verification failed: #{reason}")

        conn
        |> send_resp(401, "Unauthorized: #{reason}")
        |> halt()

      {:error, reason} ->
        Logger.error("Webhook body read failed: #{reason}")

        conn
        |> send_resp(400, "Bad Request: #{reason}")
        |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp verify_resp_body(conn) do
    headers = Enum.into(conn.req_headers, %{})
    remote_ip = extract_remote_ip(conn)

    case read_body_from_conn(conn) do
      {:ok, raw_body, decoded_body} ->
        result =
          cond do
            linear_webhook?(headers) ->
              verify_linear_webhook(headers, raw_body, remote_ip, decoded_body)

            github_webhook?(headers) ->
              :ok

            slack_webhook?(headers) ->
              :ok

            true ->
              :ok
          end

        {:ok, result, raw_body, decoded_body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_remote_ip(conn) do
    case conn.remote_ip do
      {_, _, _, _} = tuple -> :inet_parse.ntoa(tuple) |> to_string()
      ip when is_binary(ip) -> ip
      _ -> nil
    end
  end

  defp read_body_from_conn(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, _conn} ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, body, decoded}
          error -> {:error, "JSON decode error: #{inspect(error)}"}
        end

      {:more, _partial, _conn} ->
        {:error, "Request body too large"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp linear_webhook?(headers), do: Map.has_key?(headers, "linear-signature")
  defp github_webhook?(headers), do: Map.has_key?(headers, "x-github-event")
  defp slack_webhook?(headers), do: Map.has_key?(headers, "x-slack-signature")

  # See: https://linear.app/developers/webhooks#securing-webhooks
  defp verify_linear_webhook(headers, raw_body, remote_ip, decoded_body) do
    secret = Application.get_env(:swarm, :linear_webhook_secret)
    signature = Map.get(headers, "linear-signature")

    with :ok <- validate_linear_secret(secret),
         :ok <- validate_linear_signature(signature, secret, raw_body),
         :ok <- validate_linear_ip(remote_ip),
         :ok <- validate_linear_timestamp(decoded_body) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_linear_secret(secret) when is_nil(secret) or secret == "" do
    {:error, "Linear webhook secret is not configured in LINEAR_WEBHOOK_SECRET"}
  end

  defp validate_linear_secret(_), do: :ok

  defp validate_linear_signature(nil, _secret, _body),
    do: {:error, "Missing Linear-Signature header"}

  defp validate_linear_signature("", _secret, _body),
    do: {:error, "Missing Linear-Signature header"}

  defp validate_linear_signature(signature, secret, body) do
    computed =
      :crypto.mac(:hmac, :sha256, secret, body)
      |> Base.encode16(case: :lower)

    if signature == computed, do: :ok, else: {:error, "Invalid Linear webhook signature"}
  end

  defp validate_linear_ip(nil), do: :ok

  defp validate_linear_ip(remote_ip) do
    allowed_ips = [
      "35.231.147.226",
      "35.243.134.228",
      "34.140.253.14",
      "34.38.87.206",
      # smee.io webhook proxy
      "127.0.0.1"
    ]

    if remote_ip in allowed_ips,
      do: :ok,
      else: {:error, "Invalid Linear webhook sender IP: #{remote_ip}"}
  end

  defp validate_linear_timestamp(decoded_body) do
    webhook_ts =
      case decoded_body do
        %{"webhookTimestamp" => ts} -> ts
        _ -> nil
      end

    valid =
      case webhook_ts do
        ts when is_integer(ts) ->
          abs(System.system_time(:millisecond) - ts) <= 60_000

        ts when is_binary(ts) ->
          case Integer.parse(ts) do
            {int_ts, _} -> abs(System.system_time(:millisecond) - int_ts) <= 60_000
            _ -> false
          end

        _ ->
          false
      end

    if valid,
      do: :ok,
      else:
        {:error,
         "Linear webhook timestamp is not within 60 seconds of now (possible replay attack)"}
  end

  # Helper to determine event source (moved from EventController)
  defp determine_event_source(conn, params) do
    cond do
      github_event?(conn, params) -> :github
      linear_event?(conn, params) -> :linear
      slack_event?(conn, params) -> :slack
      manual_event?(params) -> :manual
      true -> :unknown
    end
  end

  defp github_event?(conn, params) do
    get_req_header(conn, "x-github-event") != [] or
      (Map.has_key?(params, "repository") and Map.has_key?(params, "sender"))
  end

  defp linear_event?(conn, params) do
    get_req_header(conn, "linear-event") != [] or
      (Map.has_key?(params, "data") and Map.has_key?(params, "action"))
  end

  defp slack_event?(conn, params) do
    get_req_header(conn, "x-slack-signature") != [] or
      (Map.has_key?(params, "event") and Map.has_key?(params, "team_id"))
  end

  defp manual_event?(params), do: params["source"] == "manual"
end
