defmodule Slax.Slack.Messages do
  @moduledoc """
  Handles various incoming Slack messages.
  """
  require Logger

  alias Slax.Slack.Messages.AppHome
  alias Slax.Slack.Messages.Help
  alias Slax.Slack.Messages.Shoutout

  def handle_message(%{"payload" => payload}) when is_binary(payload) do
    Logger.info("Incoming Message: #{inspect(payload, pretty: true)}")

    with {:ok, payload} <- Jason.decode(payload) do
      handle_message(payload)
    end
  end

  def handle_message(%{"command" => "/slax", "text" => "shoutout" <> _} = params) do
    Shoutout.call(params)
  end

  def handle_message(%{"command" => "/slax", "text" => "help" <> _} = params) do
    Help.call(params)
  end

  def handle_message(%{"callback_id" => "shoutout"} = params) do
    Shoutout.call(params)
  end

  def handle_message(%{"callback_id" => "help"} = params) do
    Help.call(params)
  end

  def handle_message(%{"event" => %{"type" => "app_home_opened"}} = params) do
    AppHome.call(params)
  end

  def handle_message(
        %{"view" => %{"callback_id" => "shoutout_modal"}, "type" => "view_submission"} = params
      ) do
    Shoutout.parse_and_insert_shoutout(params)
  end

  def handle_message(params) do
    Logger.warn("Unhandled Message: #{inspect(params, pretty: true)}")
    :ok
  end
end
