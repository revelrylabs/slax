defmodule Slax.Slack do
  @moduledoc """
  Functions for workig with the Slack API
  """
  require Logger
  alias Slax.Http

  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp api_url() do
    config()[:api_url]
  end

  defp default_channel() do
    config()[:channel_name]
  end

  defp api_token() do
    config()[:api_token]
  end

  @doc """
  Add a reaction to a message designated by channel id and timestamp
  """
  def add_reaction(%{name: name, channel_id: channel_id, timestamp: timestamp}) do
    request =
      URI.encode_query(
        token: api_token(),
        name: name,
        channel: channel_id,
        timestamp: timestamp
      )

    Http.post(
      "#{api_url()}/reactions.add",
      request,
      "Content-Type": "application/x-www-form-urlencoded"
    )
  end

  @doc """
  Add a channel
  """
  def create_channel(name) do
    request =
      URI.encode_query(
        token: api_token(),
        name: name
      )

    response =
      Http.post(
        "#{api_url()}/channels.create",
        request,
        "Content-Type": "application/x-www-form-urlencoded"
      )

    case response do
      {_, %{body: %{"ok" => true} = body}} ->
        {:ok, body["channel"]}

      {_, %{body: body}} ->
        {:error, body["error"]}
    end
  end

  @doc """
  Sends a message to slack with the given url
  """
  def send_message(url, message) do
    request = Jason.encode!(%{text: message})

    Http.post(
      url,
      request,
      "Content-Type": "application/json"
    )
  end

  @doc """
    Posts text to a given channel
  """
  def post_message_to_channel(text, channel_name \\ default_channel()) do
    request =
      URI.encode_query(
        token: api_token(),
        text: text,
        channel: channel_name,
        unfurl_links: false,
        unfurl_media: false
      )

    case Http.post(
           "#{api_url()}/chat.postMessage",
           request,
           "Content-Type": "application/x-www-form-urlencoded"
         ) do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{channel_name}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{channel_name}: #{error}")

      _ ->
        :ok
    end
  end

  @doc """
    Posts text to a given channel and thread
  """
  def post_message_to_thread(%{text: text, channel: channel, thread_ts: thread_ts}) do
    request =
      URI.encode_query(
        token: api_token(),
        text: text,
        channel: channel,
        thread_ts: thread_ts,
        unfurl_links: false,
        unfurl_media: false
      )

    case Http.post(
           "#{api_url()}/chat.postMessage",
           request,
           "Content-Type": "application/x-www-form-urlencoded"
         ) do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{channel}/#{thread_ts}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{channel}/#{thread_ts}: #{error}")

      _ ->
        :ok
    end
  end

  @doc """
    Opens a modal view
  """
  def open_modal(%{trigger_id: trigger_id, view: view}) do
    request =
      Jason.encode!(%{
        trigger_id: trigger_id,
        view: view
      })

    case Http.post(
           "#{api_url()}/views.open",
           request,
           "Content-Type": "application/json",
           Authorization: "Bearer #{api_token()}"
         ) do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      _ ->
        :ok
    end
  end

  @doc """
    Pushes a new modal view on to the modal stack (max 3)
  """
  def push_modal(%{trigger_id: trigger_id, view: view}) do
    request =
      Jason.encode!(%{
        trigger_id: trigger_id,
        view: view
      })

    case Http.post(
           "#{api_url()}/views.push",
           request,
           "Content-Type": "application/json",
           Authorization: "Bearer #{api_token()}"
         ) do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      _ ->
        :ok
    end
  end

  @doc """
    Updates an existing modal view
  """
  def update_modal(%{trigger_id: trigger_id, view: view, view_id: view_id}) do
    request =
      Jason.encode!(%{
        trigger_id: trigger_id,
        view_id: view_id,
        view: view
      })

    case Http.post(
           "#{api_url()}/views.update",
           request,
           "Content-Type": "application/json",
           Authorization: "Bearer #{api_token()}"
         ) do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      _ ->
        :ok
    end
  end

  def get_channels(%{trigger_id: trigger_id}) do
    response =
      Http.get(
        "#{api_url()}/conversations.list?exclude_archived=true&limit=999&types=public_channel,private_channel",
        "Content-Type": "application/json",
        Authorization: "Bearer #{api_token()}"
      )

    case response do
      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      {:error, error} ->
        Logger.error("Error for #{trigger_id}: #{error}")

      {_, %{body: %{"ok" => true} = body}} ->
        body["channels"]
    end
  end
end
