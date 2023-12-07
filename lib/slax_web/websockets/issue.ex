defmodule SlaxWeb.Issue do
  require Logger
  alias Slax.{Github, Slack}
  alias Slax.Channels

  def handle_event(%{"subtype" => subtype})
      when subtype in ["bot_message", "message_changed", "message_deleted"],
      do: nil

  def handle_event(%{"type" => type}) when type !== "message", do: nil

  def handle_event(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: nil

  def handle_event(%{"thread_ts" => ts, "channel" => channel, "text" => text, "type" => "message"}) do
    unless !is_nil(Channels.get_by_channel_id(channel)) and Channels.disabled?(channel) do
      issues_scan = scan_text_for_issue(text)
      prs_scan = scan_text_for_pr(text)

      reply = load_issues_from_scan(issues_scan) <> "\n" <> load_prs_from_scan(prs_scan)

      unless reply == "\n" do
        Slack.post_message_to_thread(%{text: reply, channel: channel, thread_ts: ts})
      end
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    unless !is_nil(Channels.get_by_channel_id(channel)) and Channels.disabled?(channel) do
      issues_scan = scan_text_for_issue(text)
      prs_scan = scan_text_for_pr(text)

      reply = load_issues_from_scan(issues_scan) <> "\n" <> load_prs_from_scan(prs_scan)

      unless reply == "\n" do
        Slack.post_message_to_channel(reply, channel)
      end
    end
  end

  def scan_text_for_issue(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)(#[0-9]+)}, text)
  end

  def scan_text_for_pr(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)(\$[0-9]+)}, text)
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

  defp load_prs_from_scan(repo_and_prs) do
    repo_and_prs
    |> Enum.uniq()
    |> Enum.map(fn [repo_and_pr | _] ->
      case Github.load_pr(repo_and_pr) do
        {:ok, pr, warning_message} ->
          "<#{pr["html_url"]}|#{repo_and_pr}>: [PR] #{pr["title"]} (#{pr["state"]}) #{warning_message}"

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
