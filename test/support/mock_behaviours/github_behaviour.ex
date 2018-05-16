defmodule Slax.GithubBehaviour do
  @callback authorize_url(map()) :: binary()
  @callback fetch_access_token(map()) :: binary()
  @callback current_user_info(map()) :: map()
end
