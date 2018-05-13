defmodule Slax.GithubBehaviour do
  @callback authorize_url(map()) :: binary()
end
