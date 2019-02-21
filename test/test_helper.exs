ExUnit.configure(exclude: [skip: true])
ExUnit.start()
Application.ensure_all_started(:bypass)
Ecto.Adapters.SQL.Sandbox.mode(Slax.Repo, :manual)
