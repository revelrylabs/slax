ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Slax.Repo, :manual)
Mox.defmock(Slax.Slack.RequestMock, for: Slax.Slack.Request)
{:ok, _} = Application.ensure_all_started(:ex_machina)
