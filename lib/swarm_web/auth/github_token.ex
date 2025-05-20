defmodule SwarmWeb.Auth.GitHubToken do
  @moduledoc """
  Module for generating JWT tokens for GitHub App authentication.

  See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app
  """
  use Joken.Config

  @expires_seconds 600

  @impl true
  def token_config do
    default_claims(iss: Application.get_env(:swarm, :github_client_id), default_exp: @expires_seconds, aud: "swarm")
  end

  @doc """
  Generates a JWT token for GitHub App authentication.
  """
  def create, do: generate_and_sign(%{}, Joken.Signer.create("RS256", Application.get_env(:joken, :default_signer)))
end
