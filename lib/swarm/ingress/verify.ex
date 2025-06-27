defmodule Swarm.Ingress.Verify do
  @moduledoc """
  Verifies incoming webhook events for /events endpoint.
  """
  require Logger

  def verify(raw_body, event_data, headers, remote_ip, :linear) do
    secret = Application.get_env(:swarm, :linear_webhook_secret)
    signature = Map.get(headers, "linear-signature")

    with :ok <- validate_linear_secret(secret),
         :ok <- validate_linear_signature(signature, secret, raw_body),
         :ok <- validate_linear_ip(remote_ip),
         :ok <- validate_linear_timestamp(event_data) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(_raw_body, _event_data, _headers, _remote_ip, _source), do: :ok

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
end
