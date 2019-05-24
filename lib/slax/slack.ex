defmodule Slax.Slack do
  @moduledoc """
  Functions for workig with the Slack API
  """
  alias Slax.Http

  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp api_url() do
    config()[:api_url]
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
    request = Jason.encode!(message)

    Http.post(
      url,
      request,
      "Content-Type": "application/json"
    )
  end

  @doc """
    posts text to a given channel
  """
  def post_message_to_channel(%{text: text, channel_name: channel_name}) do
    request =
      URI.encode_query(
        token: api_token(),
        text: text,
        channel: channel_name
      )

    {:ok, response} = Http.post(
      "#{api_url()}/chat.postMessage",
      request,
      "Content-Type": "application/x-www-form-urlencoded"
    )

    case response do
      %{body: %{"ok" => false, "error" => error}} ->
        IO.puts "Error for #{channel_name}: #{error}"
      _ ->
        :ok
    end
  end
end
