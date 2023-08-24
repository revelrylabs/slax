defmodule SlaxWeb.Issue do
  require Logger
  alias Slax.{Github, Slack}

  def handle_event(%{"subtype" => subtype}) when subtype in ["bot_message", "message_changed"],
    do: nil

  def handle_event(%{"type" => type}) when type !== "message", do: nil

  def handle_event(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: nil

  def handle_event(%{"thread_ts" => ts, "channel" => channel, "text" => text, "type" => "message"}) do
    with true <- String.match?(text, ~r{([\S-]+/)?([\S-]+)?(#[0-9]+)}),
         {:ok, issue} <- load_issue(text) do
      repo_and_issue =
        Regex.replace(~r".*/repos/(\S+)/(\S+)/issues/(\d+)$", issue["url"], "\\1/\\2/\\3")

      Slack.post_message_to_thread(%{
        text:
          "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)}",
        channel: channel,
        thread_ts: ts
      })
    else
      false ->
        nil

      {:error, repo_and_issue} ->
        Slack.post_message_to_thread(%{
          text: "Issue #{repo_and_issue}: not found",
          channel: channel,
          thread_ts: ts
        })
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    with true <- String.match?(text, ~r{([\S-]+/)?([\S-]+)?(#[0-9]+)}),
         {:ok, issue} <- load_issue(text) do
      repo_and_issue =
        Regex.replace(~r".*/repos/(\S+)/(\S+)/issues/(\d+)$", issue["url"], "\\1/\\2/\\3")

      Slack.post_message_to_channel(%{
        text:
          "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)}",
        channel_name: channel
      })
    else
      false ->
        nil

      {:error, repo_text} ->
        Slack.post_message_to_channel(%{
          text: "Issue #{repo_text}: not found",
          channel_name: channel
        })
    end
  end

  defp load_issue(repo_and_issue) do
    repo_and_issue
    |> Github.parse_repo_org_issue()
    |> case do
      {org, repo, issue} ->
        client = Tentacat.Client.new(%{access_token: Github.api_token()})

        case Tentacat.Issues.find(client, org, repo, issue) do
          {200, issue, _http_response} ->
            {:ok, issue}

          {_response_code, %{"message" => error_message}, _http_response} ->
            Logger.info(error_message)
            {:error, repo_and_issue}
        end

      {:error, _message} = error ->
        {:error, repo_and_issue}
    end
  end

  defp labels_for_issue(issue) do
    column_label =
      cond do
        not is_nil(issue["closed_at"]) ->
          ["closed"]

        Enum.empty?(issue["labels"]) ->
          ["icebox"]

        true ->
          []
      end

    all_labels =
      issue["labels"]
      |> Enum.map(& &1["name"])
      |> Enum.concat(column_label)
      |> Enum.join(", ")

    "(#{all_labels})"
  end
end
