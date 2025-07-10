defmodule Swarm.Tools.Git do
  @moduledoc false

  alias Swarm.Tools.Git.Repo

  def all_tools(mode \\ :read_write) do
    Repo.all_tools(mode)
  end
end
