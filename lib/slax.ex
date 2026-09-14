defmodule Slax do
  @moduledoc false
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      [
        Slax.Repo,
        SlaxWeb.Endpoint,
        Slax.Scheduler,
        {Oban, Application.fetch_env!(:slax, Oban)},
        {Task.Supervisor, name: Slax.TaskSupervisor}
      ] ++ optional_children()

    opts = [strategy: :one_for_one, name: Slax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    SlaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp optional_children() do
    enabled? = Application.get_env(:slax, SlaxWeb.WebsocketListener, [])[:enabled]
    app_token = Application.get_env(:slax, Slax.Slack, [])[:app_token]

    cond do
      !enabled? ->
        []

      app_token in [nil, ""] ->
        Logger.warning(
          "SlaxWeb.WebsocketListener is enabled but Slax.Slack has no app_token. " <>
            "Starting without the Slack socket listener. " <>
            "In dev, set app_token in config/dev.secret.exs to connect to Slack."
        )

        []

      true ->
        [SlaxWeb.WebsocketListener]
    end
  end
end
