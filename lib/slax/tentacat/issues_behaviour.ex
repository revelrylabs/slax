defmodule Slax.Tentacat.IssuesBehaviour do
  @moduledoc false
  @callback find(map(), String.t(), String.t(), String.t()) :: {integer(), map(), map()}
end
