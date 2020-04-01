defmodule Slax.EventSink do
  @moduledoc """
  Functions for working with the Github API
  """
  alias Slax.Http

  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp secret() do
    Keyword.get(config(), :issue_events_secret)
  end

  @doc """
  Fetch issue events
  """
  def fetch_issues_events(params, issues) when is_list(issues) do
    issue_ids =
      issues
      |> Enum.map(& &1["number"])
      |> Enum.join(",")

    signature =
      :crypto.hash(
        :sha256,
        "#{secret()}:#{issue_ids}"
      )
      |> Base.url_encode64()

    url =
      "https://event-sink.prod.revelry.net/api/issue/events/#{params[:org]}/#{params[:repo]}?issue_ids=#{
        issue_ids
      }&signature=#{signature}"

    response = Http.get(url)

    case response do
      {:ok, %{body: body}} ->
        body

      {:error, %{body: body}} ->
        body
    end
  end
end
