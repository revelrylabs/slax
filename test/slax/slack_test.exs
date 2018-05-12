defmodule Slax.Slack.Test do
  use Slax.ModelCase, async: true
  alias Slax.Slack

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Slack,
      api_url: url,
      api_token: "token"
    )

    {:ok, bypass: bypass}
  end
end
