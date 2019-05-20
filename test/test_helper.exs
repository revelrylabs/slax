Mox.defmock(Slax.HttpMock, for: Slax.Http.Behaviour)
Mox.defmock(Slax.Commands.GithubCommandsMock, for: Slax.Commands.GithubCommands.Behaviour)
Slax.Command.GithubCommandMock
ExUnit.configure(exclude: [skip: true])
ExUnit.start()
Application.ensure_all_started(:bypass)
Ecto.Adapters.SQL.Sandbox.mode(Slax.Repo, :manual)
