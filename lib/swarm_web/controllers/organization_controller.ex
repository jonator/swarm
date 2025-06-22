defmodule SwarmWeb.OrganizationController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Organizations

  action_fallback SwarmWeb.FallbackController

  def index(conn, _params, user) do
    organizations = Organizations.list_organizations(user)
    render(conn, :index, organizations: organizations)
  end

  def create(conn, %{"organization" => params}, user) do
    with {:ok, organization} <- Organizations.create_organization_with_user(user, params) do
      conn
      |> put_status(:created)
      |> render(:show, organization: organization)
    end
  end

  def update(conn, %{"id" => id} = attrs, user) do
    user_organizations = Organizations.list_organizations(user)

    # TODO: ensure admin vs member access

    with organization <- Enum.find(user_organizations, &(&1.id == String.to_integer(id))),
         {:ok, organization} <- Organizations.update_organization(organization, attrs) do
      render(conn, :show, organization: organization)
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Organization not found"})
    end
  end
end
