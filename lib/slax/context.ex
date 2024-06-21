defmodule Slax.Context do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import Ecto.Query, warn: false
      alias Ecto.{Changeset, Multi}
      alias Slax.Repo
    end
  end
end
