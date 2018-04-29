defmodule Slax.Command do
  @doc "Defines the help command output"
  @callback help(any, list(binary())) :: binary()
end
