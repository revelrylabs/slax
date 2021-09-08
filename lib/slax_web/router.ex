defmodule SlaxWeb.Router do
  use SlaxWeb, :router
  alias SlaxWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SlaxWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.LoadUser
  end

  pipeline :require_anonymous do
    plug Plugs.RequireAnonymous
  end

  pipeline :require_authenticated do
    plug Plugs.RequireAuthenticated
  end

  pipeline :slack do
    plug :accepts, ["json"]
  end

  scope "/", SlaxWeb do
    pipe_through :slack
    post "/slack/message", SlackController, :message
  end

  scope "/", SlaxWeb do
    pipe_through [:browser]
    live "/terms", LiveViews.Terms
    live "/privacy", LiveViews.Privacy
    live "/support", LiveViews.Support
  end

  scope "/", SlaxWeb do
    pipe_through [:browser, :require_anonymous]
    live "/", LiveViews.Home
    get "/auth", SlackController, :auth
  end

  scope "/", SlaxWeb do
    pipe_through [:browser, :require_authenticated]
    live "/account", LiveViews.Account
    live "/setup_step_1", LiveViews.SetupStep1
    live "/setup_step_2", LiveViews.SetupStep2
    live "/setup_step_3", LiveViews.SetupStep3
    live "/setup_success", LiveViews.SetupSuccess
    live "/account/delete", LiveViews.Account.Delete
    live "/settings", LiveViews.Settings
    get "/shoutouts/:team_id/csv_download", ShoutoutController, :csv_download
    get "/sign_out", SlackController, :sign_out
    live "/styleguide", LiveViews.Styleguide
  end
end
