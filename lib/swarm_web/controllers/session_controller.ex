defmodule SwarmWeb.SessionController do
  use SwarmWeb, :controller

  alias Swarm.Accounts
  alias SwarmWeb.Auth.Guardian
  alias SwarmWeb.Auth.OTP

  action_fallback SwarmWeb.FallbackController

  def email_otp(conn, %{"email" => email, "code" => code}) do
    case SwarmWeb.Auth.OTP.validate(email, code) do
      :ok ->
        with {:ok, user} <- Accounts.get_or_create_user_by_email(email),
             opts <-
               if(user.role == :admin, do: [permissions: %{default: [:admin]}], else: []),
             {:ok, token, _claims} <- Guardian.encode_and_sign(user, %{}, opts) do
          conn
          |> put_status(:created)
          |> json(%{token: token})
        end

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def email_otp(conn, %{"email" => email}) do
    # Generate and store OTP code
    otp = OTP.generate_and_store(email)

    # Send email with OTP code
    Swoosh.Email.new()
    |> Swoosh.Email.from("noreply@swarm.com")
    |> Swoosh.Email.reply_to("noreply@swarm.com")
    |> Swoosh.Email.to(email)
    |> Swoosh.Email.subject("Swarm Login Code")
    |> Swoosh.Email.text_body("Your code is #{otp}")
    |> Swarm.Mailer.deliver()

    conn
    |> put_status(:ok)
    |> json(%{message: "OTP code sent to your email"})
  end
end
