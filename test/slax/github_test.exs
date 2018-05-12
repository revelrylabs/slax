defmodule Slax.Github.Test do
  use Slax.ModelCase, async: true
  alias Slax.Github

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Github,
      api_url: url,
      oauth_url: url
    )

    {:ok, bypass: bypass}
  end
end
