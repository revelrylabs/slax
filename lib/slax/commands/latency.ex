defmodule Slax.Commands.Latency do
  @moduledoc """
  Functions for the latency command. Functions in this module filter issue events
  and format the issues and events into text for presentation.
  """
  def filter_issues_events(issue_events) do
    status_labels = ["in progress", "in review", "qa", "uat", "up next"]

    issue_events
    |> Enum.filter(&(Enum.member?(["labeled", "unlabeled"], &1["action"])))
    |> Enum.filter(fn event ->
        label_name =
          event["label"]["name"]
          |> String.downcase()
          |> String.strip()

        Enum.member?(status_labels, label_name)
    end)
  end

  @doc """
  Filters list of issues from issues events request
  threshold for filtering is based from
  set column threshold and labeled date
  """
  def add_events_to_issues(issues, issues_events) do
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
    formatted_list = results
    |> Enum.map(&format_issue(&1))
    |> Enum.join("")

    date = DateTime.utc_now
    today = date
    |> Timex.weekday()
    |> Timex.day_name()
    ":snail:  *Latent Issues for #{today}, #{date.month}/#{date.day}* :slowpoke:
    Ways to take ownership:
    - Update ticket to correct column
    - Pair
    - Comment blockers (even if you don't know)
    - Escalate in channel (or another channel)\n\n"<> formatted_list
  end

  defp format_issue(issue) do
    labels =
      issue["labels"]
        |> Enum.map(& &1["name"])
        |> Enum.map(&(String.downcase(&1)))

    [status, status_as_of] = calculate_status_from_events(issue["events"])
    {:ok, status_timestamp, _} = DateTime.from_iso8601(status_as_of)
    status_seconds = DateTime.diff(DateTime.utc_now(), status_timestamp)
    status_duration = Timex.Duration.from_seconds(status_seconds)

    if Enum.member?(["in progress", "in review", "qa", "uat"], status) &&
       status_seconds > 18 * 60 * 60 do
      {:ok, timestamp, _} = DateTime.from_iso8601(issue["updated_at"])
      seconds = DateTime.diff(DateTime.utc_now(), timestamp)
      duration = Timex.Duration.from_seconds(seconds)

      assignees =
        case issue["assignees"] do
          [] ->
            "_No one._"
          _ ->
            issue["assignees"] |> Enum.map(&(&1["login"]))
        end

      events =
        issue["events"]
        |> Enum.map(fn event ->
          "#{event["action"]} #{event["label"]["name"]} (#{event["created_at"]})"
        end)
        |> Enum.join(", ")

      {:ok, update_time_string} = Elixir.Timex.Format.DateTime.Formatters.Relative.format(timestamp, "{relative}")
      {:ok, status_time_string} = Elixir.Timex.Format.DateTime.Formatters.Relative.format(status_timestamp, "{relative}")

      issue_link = "<https://github.com/#{issue[:org]}/#{issue[:repo]}/issues/#{issue["number"]}|#{issue[:org]}/#{issue[:repo]}##{issue["number"]}>"

      "*#{issue["title"] |> String.strip()}* (#{issue_link})\n" <>
      "Status: #{status} for #{status_time_string}\n" <>
      "Last Updated: #{update_time_string}\n" <>
      "Assigned to: #{assignees}\n\n"
    else
      ""
    end
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
