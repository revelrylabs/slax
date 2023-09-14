defmodule Slax.Tentacat.IssuesBehaviour do
  @callback find(map(), String.t(), String.t(), String.t()) :: {integer(), map(), map()}
end
