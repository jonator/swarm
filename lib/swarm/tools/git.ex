defmodule Swarm.Tools.Git do
  @moduledoc false

  alias Swarm.Tools.Git.Repo
  alias Swarm.Tools.Git.Index

  def all_tools(mode \\ :read_write) do
    Repo.all_tools(mode) ++ Index.all_tools(mode)
  end
end
