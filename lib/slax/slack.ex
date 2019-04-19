defmodule Slax.Slack do
  @moduledoc """
  Functions for workig with the Slack API
  """

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

    HTTPotion.post(
      "#{api_url()}/reactions.add",
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      body: request
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
      HTTPotion.post(
        "#{api_url()}/channels.create",
        headers: ["Content-Type": "application/x-www-form-urlencoded"],
        body: request
      )

    body = Jason.decode!(response.body)

    case body["ok"] do
      true -> {:ok, body["channel"]}
      false -> {:error, body["error"]}
    end
  end

  @doc """
  Sends a message to slack with the given url
  """
  def send_message(url, message) do
    request = Jason.encode!(message)

    HTTPotion.post(
      url,
      headers: ["Content-Type": "application/json"],
      body: request
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

      HTTPotion.post(
      "#{api_url()}/chat.postMessage",
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      body: request
    )
  end

end
