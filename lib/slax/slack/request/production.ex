defmodule Slax.Slack.Request.Production do
  @moduledoc """
  Defines an API for making requests to the Slack API.
  """
  @behaviour Slax.Slack.Request

  require Logger

  @base_url "https://slack.com/api"

  @impl Slax.Slack.Request
  def get(method, params, token \\ nil) do
    url = get_url(method) |> add_params(params)

    with {:ok, %{body: body, status_code: status_code}} <- HTTPoison.get(url, headers(token)),
         {:ok, response} <- Jason.decode(body) do
      log(method, params, status_code, response)
      {:ok, response, status_code}
    else
      error ->
        Logger.error(inspect(error))
        error
    end
  end

  @impl Slax.Slack.Request
  def post(method, body, token \\ nil) do
    with {:ok, json} <- Jason.encode(body),
         url = get_url(method),
         {:ok, %{body: body, status_code: status_code}} <-
           HTTPoison.post(url, json, headers(token)),
         {:ok, response} <- Jason.decode(body) do
      log(method, body, status_code, response)
      {:ok, response, status_code}
    else
      error ->
        Logger.error(inspect(error))
        error
    end
  end

  defp get_url(method), do: @base_url <> "/" <> method

  defp headers(token, additional_headers \\ []) do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{token}"},
      {"Accepts", "application/json"},
      {"charset", "utf-8"}
    ] ++ additional_headers
  end

  defp add_params(url, params) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end

  defp log(method, params, status_code, response) do
    Logger.debug("""
      SLACK GET REQUEST
      ---
      Method: #{method}
      Status Code: #{status_code}
      Params: #{inspect(params)}
      Response: #{inspect(response, pretty: true)}
    """)
  end
end
