defmodule Slax.Commands.Latency do
  alias Slax.{Github, EventSink}
  alias Elixir.Timex.Format.DateTime.Formatters.{Relative}

  @moduledoc """
  Functions for the latency command. Functions in this module filter issue events
  and format the issues and events into text for presentation.
  """
  def text_for_org_and_repo(org_name, repo_name, github_access_token) do
    params = %{
      repo: repo_name,
      access_token: github_access_token,
      org: org_name,
    }

    issues = Github.fetch_issues(params)
    events =
      params
      |> EventSink.fetch_issues_events(issues)
      |> filter_issues_events()

    issues
    |> add_events_to_issues(events)
    |> format_response()
  end

  defp filter_issues_events(issue_events) do
    status_labels = ["in progress", "in review", "qa", "uat", "up next"]

    issue_events
    |> Enum.filter(&(Enum.member?(["labeled", "unlabeled"], &1["action"])))
    |> Enum.filter(fn event ->
        label_name =
          event["label"]["name"]
          |> String.downcase()
          |> String.trim()

        Enum.member?(status_labels, label_name)
    end)
  end

  defp add_events_to_issues(issues, issues_events) do
    issues_events = filter_issues_events(issues_events)

    issues
    |> Enum.map(fn issue ->
      Map.put(issue, "events", Enum.filter(issues_events, fn issue_event ->
        issue["number"] == issue_event["issue"]["number"]
      end))
    end)
  end

  @doc """
  Formats list of issues to be displayed nicely within Slack
  """
  def format_response(results) do
    formatted_list =
      results
      |> Enum.filter(&issue_is_latent/1)
      |> Enum.map(&format_issue(&1))
      |> Enum.join("")

    date = DateTime.utc_now
    today = date
    |> Timex.weekday()
    |> Timex.day_name()
    ":snail:  *Unmoved Issues for #{today}, #{date.month}/#{date.day}* :slowpoke:
    Ways to take ownership:
    - Update ticket to correct column
    - Pair
    - Comment blockers (even if you don't know)
    - Escalate in channel (or another channel)\n\n"<> formatted_list
  end

  defp format_issue(issue) do
    [status, status_as_of] = calculate_status_from_events(issue["events"])
    {:ok, status_timestamp, _} = DateTime.from_iso8601(status_as_of)
    {:ok, timestamp, _} = DateTime.from_iso8601(issue["updated_at"])

    assignees =
      case issue["assignees"] do
        [] ->
          "_No one._"
        _ ->
          issue["assignees"] |> Enum.map(&(&1["login"]))
      end

    {:ok, update_time_string} = Relative.format(timestamp, "{relative}")
    {:ok, status_time_string} = Relative.format(status_timestamp, "{relative}")

    issue_link = "<https://github.com/#{issue[:org]}/#{issue[:repo]}/issues/#{issue["number"]}|#{issue[:org]}/#{issue[:repo]}##{issue["number"]}>"

    "*#{issue["title"] |> String.trim()}* (#{issue_link})\n" <>
    "Status: #{status} for #{status_time_string}\n" <>
    "Last Updated: #{update_time_string}\n" <>
    "Assigned to: #{assignees}\n\n"
  end

  defp issue_is_latent(issue) do
    eighteen_hours_in_seconds = 18 * 60 * 60

    [status, status_as_of] = calculate_status_from_events(issue["events"])
    {:ok, status_timestamp, _} = DateTime.from_iso8601(status_as_of)
    status_seconds = DateTime.diff(DateTime.utc_now(), status_timestamp)

    Enum.member?(["in progress", "in review", "qa", "uat"], status) &&
    status_seconds > eighteen_hours_in_seconds
  end

  defp calculate_status_from_events(events) do
    first_timestamp =
      case events do
        [] ->
          DateTime.utc_now() |> DateTime.to_iso8601()
        _ ->
          events
          |> Enum.at(0)
          |> Map.get("created_at")
      end

    update_status_from_new_event =
      fn event, status ->
        case event["action"] do
          "labeled" ->
            [event["label"]["name"], event["created_at"]]
          "unlabeled" ->
            [old_status, _] = status
            if old_status == event["label"]["name"] do
              [nil, event["created_at"]]
            else
              status
            end
        end
      end

    events
    |> Enum.reduce([nil, first_timestamp], update_status_from_new_event)
  end
end
