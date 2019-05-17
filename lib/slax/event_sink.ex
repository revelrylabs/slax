defmodule Slax.EventSink do
  @moduledoc """
  Functions for working with the Github API
  """
  alias Slax.Http
  alias Slax.Http.Error

  @doc """
  Fetch issue events
  """
  def fetch_issues_events(params, issues) do
    {:ok, secret} =
      Application.get_env(:slax, Slax.EventSink, :issue_events_secret)
      |> Keyword.fetch(:issue_events_secret)

    issue_ids =
      issues
      |> Enum.map(&(&1["number"]))
      |> Enum.join(",")

    signature =
      :crypto.hash(
        :sha256,
        "#{secret}:#{issue_ids}"
      )
      |> Base.url_encode64()

    url = "https://event-sink.prod.revelry.net/api/issue/events/#{params[:org]}/#{params[:repo]}?issue_ids=#{issue_ids}&signature=#{signature}"

    response = Http.get(url)

    case response do
      {:ok, %{body: body}} ->
        body
      {:error, %{body: body}} ->
        body
    end
  end
end
