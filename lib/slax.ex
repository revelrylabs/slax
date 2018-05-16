defmodule Slax do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Slax.Repo, []),
      supervisor(SlaxWeb.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: Slax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    SlaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
