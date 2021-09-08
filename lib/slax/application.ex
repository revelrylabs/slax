defmodule Slax.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children =
      [
        {Registry, keys: :unique, name: Slax.Registry},
        Slax.Repo,
        SlaxWeb.Telemetry,
        {Phoenix.PubSub, name: Slax.PubSub},
        SlaxWeb.Endpoint,
        {Oban, Application.get_env(:slax, Oban)},
        Slax.Vault
      ] ++ Application.get_env(:slax, :extra_children, [])

    opts = [strategy: :one_for_one, name: Slax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    SlaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
