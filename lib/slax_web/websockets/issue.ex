defmodule SlaxWeb.Issue do
  require Logger
  alias Slax.{Github, Slack}

  def handle_event(%{"subtype" => subtype}) when subtype in ["bot_message", "message_changed"],
    do: nil

  def handle_event(%{"type" => type}) when type !== "message", do: nil

  def handle_event(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: nil

  def handle_event(%{"thread_ts" => ts, "channel" => channel, "text" => text, "type" => "message"}) do
    with issues when issues != [] <- Regex.scan(~r{([\w-]+/)?([\w-]+)(#[0-9]+)}, text) do
      reply = load_issues_from_scan(issues)
      Slack.post_message_to_thread(%{text: reply, channel: channel, thread_ts: ts})
    else
      [] ->
        nil
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    with issues when issues != [] <- Regex.scan(~r{([\w-]+/)?([\w-]+)(#[0-9]+)}, text) do
      reply = load_issues_from_scan(issues)
      Slack.post_message_to_channel(%{text: reply, channel_name: channel})
    else
      [] ->
        nil
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
            "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)}"

          {_response_code, %{"message" => error_message}, _http_response} ->
            "Issue #{repo_and_issue}: not found"
        end

      {:error, message} = error ->
        message
    end
  end

  defp load_issues_from_scan(issues) do
    issues
    |> Enum.map(fn [issue | _] -> load_issue(issue) end)
    |> Enum.join("\n")
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
