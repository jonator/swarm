defmodule SwarmWeb.Auth.OTP do
  @moduledoc """
  Handles OTP code generation and storage using ETS.
  """

  # OTP codes expire after 5 minutes
  @expiry_time 5 * 60
  @table_name :otp_codes

  @doc """
  Starts the OTP ETS table. Should be called when your application starts.
  """
  def start do
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])
  end

  @doc """
  Generates a 6-digit OTP code for the given email and stores it in ETS.
  Returns the generated OTP code.
  """
  def generate_and_store(email) when is_binary(email) do
    # Delete any existing OTP for this email
    :ets.delete(@table_name, email)

    # Generate a random 6-digit code
    code = :rand.uniform(900_000) + 100_000
    expiry = System.system_time(:second) + @expiry_time

    # Store in ETS with expiry timestamp
    :ets.insert(@table_name, {email, to_string(code), expiry})

    to_string(code)
  end

  @doc """
  Validates the OTP code for the given email.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate(email, code) when is_binary(email) and is_binary(code) do
    case :ets.lookup(@table_name, email) do
      [{^email, stored_code, expiry}] ->
        cond do
          System.system_time(:second) > expiry ->
            :ets.delete(@table_name, email)
            {:error, :expired}

          stored_code == code ->
            :ets.delete(@table_name, email)
            :ok

          true ->
            {:error, :invalid_code}
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Cleans up expired OTP codes from the ETS table.
  """
  def cleanup_expired do
    now = System.system_time(:second)

    :ets.select_delete(@table_name, [
      {
        {:_, :_, :"$1"},
        [{:<, :"$1", now}],
        [true]
      }
    ])
  end
end
