defmodule SlaxWeb.Issue do
  require Logger
  alias Slax.Channels
  alias Slax.{Github, Slack}

  def handle_event(%{"subtype" => subtype})
      when subtype in ["bot_message", "message_changed", "message_deleted"],
      do: nil

  def handle_event(%{"type" => type}) when type !== "message", do: nil

  def handle_event(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: nil

  def handle_event(%{"thread_ts" => ts, "channel" => channel, "text" => text, "type" => "message"}) do
    issues_scan = scan_text_for_issue(text)

    reply = load_prs_and_issues_from_scan(issues_scan, channel)

    unless reply == "" do
      Slack.post_message_to_thread(%{text: reply, channel: channel, thread_ts: ts})
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    issues_scan = scan_text_for_issue(text)

    reply = load_prs_and_issues_from_scan(issues_scan, channel)

    unless reply == "" do
      Slack.post_message_to_channel(reply, channel)
    end
  end

  def scan_text_for_issue(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)?(#[0-9]+)}, text)
  end

  defp load_prs_and_issues_from_scan(repo_and_issues, channel) do
    repo_and_issues
    |> Enum.uniq()
    |> Enum.map(fn [repo_and_issue, _, repo_name, issue_number] ->
      case repo_name do
        "" ->
          default_repo = Channels.maybe_get_default_repo(channel)

          case default_repo do
            nil ->
              "No default repo set for this channel"

            _ ->
              org_name = default_repo.org_name
              repo_name = default_repo.repo_name
              issue_number = String.slice(issue_number, 1..-1)
              load_pr_or_issue_from_github("#{org_name}/#{repo_name}##{issue_number}")
          end

        _ ->
          load_pr_or_issue_from_github(repo_and_issue)
      end
    end)
    |> Enum.join("\n")
  end

  defp load_pr_or_issue_from_github(repo_and_issue) do
    case Github.load_issue(repo_and_issue) do
      {:ok, %{"pull_request" => _pr}, _warning_message} ->
        load_pr_from_github(repo_and_issue)

      {:ok, issue, warning_message} ->
        "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)} #{warning_message}"

      {:error, error} ->
        error
    end
  end

  defp load_pr_from_github(repo_and_pr) do
    case Github.load_pr(repo_and_pr) do
      {:ok, pr, warning_message} ->
        "<#{pr["html_url"]}|#{repo_and_pr}>: [PR] #{pr["title"]} (#{pr["state"]}) #{warning_message}"

      {:error, error} ->
        error
    end
  end

  def labels_for_issue(issue) do
    column_label =
      cond do
        not is_nil(issue["closed_at"]) ->
          ["closed"]

        issue["draft"] == true ->
          ["draft"]

        true ->
          []
      end

    all_labels =
      issue["labels"]
      |> Enum.map(& &1["name"])
      |> Enum.concat(column_label)
      |> Enum.join(", ")

    IO.inspect(all_labels, label: "labels")
    if all_labels == "", do: "", else: "(#{all_labels})"
  end
end
