defmodule Slax.Tentacat.PrsBehaviour do
  @callback find(map(), String.t(), String.t(), String.t()) :: {integer(), map(), map()}
end
