defmodule SlaxWeb.Issue do
  @moduledoc false
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
    prs_scan = scan_text_for_pr(text)

    reply =
      load_issues_from_scan(issues_scan, channel) <> "\n" <> load_prs_from_scan(prs_scan, channel)

    unless reply == "\n" do
      Slack.post_message_to_thread(%{text: reply, channel: channel, thread_ts: ts})
    end
  end

  def handle_event(%{"channel" => channel, "text" => text, "type" => "message"}) do
    issues_scan = scan_text_for_issue(text)
    prs_scan = scan_text_for_pr(text)

    reply =
      load_issues_from_scan(issues_scan, channel) <> "\n" <> load_prs_from_scan(prs_scan, channel)

    unless reply == "\n" do
      Slack.post_message_to_channel(reply, channel)
    end
  end

  def scan_text_for_issue(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)?(#[0-9]+)}, text)
  end

  def scan_text_for_pr(text) do
    Regex.scan(~r{([\w-]+/)?([\w-]+)?(\$[0-9]+)}, text)
  end

  defp load_issues_from_scan(repo_and_issues, channel) do
    repo_and_issues
    |> Enum.uniq()
    |> Enum.map_join("\n", fn [repo_and_issue, _, repo_name, issue_number] ->
      load_from_github(repo_and_issue, issue_number, repo_name, :issue, channel)
    end)
  end

  defp load_from_github(repo_and_issue, issue_number, repo_name, :issue, channel) do
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
            load_issue_from_github("#{org_name}/#{repo_name}##{issue_number}")
        end

      _ ->
        load_issue_from_github(repo_and_issue)
    end
  end

  defp load_from_github(repo_and_pr, pr_number, repo_name, :pr, channel) do
    case repo_name do
      "" ->
        default_repo = Channels.maybe_get_default_repo(channel)

        case default_repo do
          nil ->
            "No default repo set for this channel"

          _ ->
            org_name = default_repo.org_name
            repo_name = default_repo.repo_name
            pr_number = String.slice(pr_number, 1..-1)
            load_pr_from_github("#{org_name}/#{repo_name}$#{pr_number}")
        end

      _ ->
        load_pr_from_github(repo_and_pr)
    end
  end

  defp load_issue_from_github(repo_and_issue) do
    case Github.load_issue(repo_and_issue) do
      {:ok, issue, warning_message} ->
        "<#{issue["html_url"]}|#{repo_and_issue}>: #{issue["title"]} #{labels_for_issue(issue)} #{warning_message}"

      {:error, error} ->
        error
    end
  end

  defp load_prs_from_scan(repo_and_prs, channel) do
    repo_and_prs
    |> Enum.uniq()
    |> Enum.map_join("\n", fn [repo_and_pr, _, repo_name, pr_number] ->
      load_from_github(repo_and_pr, pr_number, repo_name, :pr, channel)
    end)
  end

  defp load_pr_from_github(repo_and_pr) do
    case Github.load_pr(repo_and_pr) do
      {:ok, pr, warning_message} ->
        "<#{pr["html_url"]}|#{repo_and_pr}>: [PR] #{pr["title"]} (#{pr["state"]}) #{warning_message}"

      {:error, error} ->
        error
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
