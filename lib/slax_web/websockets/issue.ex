defmodule SlaxWeb.Issue do
  require Logger
  alias Slax.{Github, Slack}

  def handle_event(%{"subtype" => subtype})
      when subtype in ["bot_message", "message_changed", "message_deleted"],
      do: nil

  def handle_event(%{"type" => type}) when type !== "message", do: nil

  def handle_event(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: nil

  def handle_event(%{"thread_ts" => ts, "channel" => channel, "text" => text, "type" => "message"}) do
    with repo_and_issues when repo_and_issues != [] <- scan_text_for_issue(text) do
      reply = load_issues_from_scan(repo_and_issues)
      Slack.post_message_to_thread(%{text: reply, channel: channel, thread_ts: ts})
    else
      [] ->
        nil
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    with repo_and_issues when repo_and_issues != [] <- scan_text_for_issue(text) do
      reply = load_issues_from_scan(repo_and_issues)
      Slack.post_message_to_channel(reply, channel)
    else
      [] ->
        nil
    end
  end

  def scan_text_for_issue(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)(#[0-9]+)}, text)
  end

  defp load_issues_from_scan(repo_and_issues) do
    repo_and_issues
    |> Enum.uniq()
    |> Enum.map(fn [repo_and_issue | _] ->
      case Github.load_issue(repo_and_issue) do
        {:ok, issue, warning_message} ->
          "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)} #{warning_message}"

        {:error, error} ->
          error
      end
    end)
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
