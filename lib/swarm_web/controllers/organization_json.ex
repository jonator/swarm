defmodule SwarmWeb.OrganizationJSON do
  alias Swarm.Organizations.Organization

  @doc """
  Renders a list of organizations.
  """
  def index(%{organizations: organizations}) do
    %{organizations: for(organization <- organizations, do: data(organization))}
  end

  @doc """
  Renders a single organization.
  """
  def show(%{organization: organization}) do
    %{organization: data(organization)}
  end

  defp data(%Organization{} = organization) do
    %{
      id: organization.id,
      name: organization.name,
      github_installation_id: organization.github_installation_id,
      created_at: organization.inserted_at,
      updated_at: organization.updated_at
    }
  end
end
