defmodule Slack do
  @moduledoc """
  Functions for workig with the Slack API
  """

  @api_url "https://slack.com/api"
  @api_token System.get_env("SLACK_TOKEN")

  @doc """
  Add a reaction to a message designated by channel id and timestamp
  """
  def add_reaction(%{name: name, channel_id: channel_id, timestamp: timestamp}) do
    request = URI.encode_query([
      token: @api_token,
      name: name,
      channel: channel_id,
      timestamp: timestamp
    ])

    HTTPotion.post("#{@api_url}/reactions.add", [
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      body: request
    ])
  end

  @doc """
  Add a channel
  """
  def create_channel(name) do
    request = URI.encode_query([
      token: @api_token,
      name: name
    ])

    response = HTTPotion.post("#{@api_url}/channels.create", [
          headers: ["Content-Type": "application/x-www-form-urlencoded"],
          body: request
        ])

    body = Poison.decode!(response.body)

    case body["ok"] do
      true -> {:ok, body["channel"]}
      false -> {:error, body["error"]}
    end

  end
end
