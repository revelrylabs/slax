require IEx

defmodule Slack do
  @moduledoc """
  Functions for workig with the Github API
  """

  @api_url "https://slack.com/api"
  @api_token System.get_env("SLACK_TOKEN")

  def add_reaction(%{name: name, channel_id: channel_id, timestamp: timestamp}) do
    request = URI.encode_query([
      token: @api_token,
      name: name,
      channel: channel_id,
      timestamp: timestamp
    ])

    response = HTTPotion.post("#{@api_url}/reactions.add", [
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      body: request
    ])
  end
end
