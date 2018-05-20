defmodule Slax.Commands.ProjectVelocity do
  alias Slax.Integrations
  @sprint_length_in_days 6

  @moduledoc """
  Finds the Velocity for sprints
  """

  @doc """
  Gets the velocity for the given sprint.
  The issues in the originally set in the
  sprint are taken from the given `milestone_number.
  GitHub events are traversed all the way back
  to the given `start_time`. From there, closed
  events and labeled events of `uat` are taken
  into account

  """
  @spec calculate_sprint_velocity(binary, binary, integer, DateTime.t(), integer) ::
          {:ok, map} | {:error, any}
  def calculate_sprint_velocity(
        owner,
        repo,
        milestone_number,
        start_time,
        sprint_length_in_days \\ @sprint_length_in_days
      )

  def calculate_sprint_velocity(
        owner,
        repo,
        milestone_number,
        start_time,
        sprint_length_in_days
      ) do
    with {:ok, %{issues: issues_in_sprint, points: points_in_sprint}} <-
           get_issues_in_milestone(owner, repo, milestone_number),
         end_time = calculate_end_time(start_time, sprint_length_in_days),
         {:ok, events} <- repo_events_in_sprint(owner, repo, start_time, end_time) do
      completed_issues =
        events
        |> issues_from_relevent_events()
        |> process_issues()

      completed_points = accumulate_points(completed_issues)

      {:ok,
       %{
         sprint: %{
           issues: issues_in_sprint,
           points: points_in_sprint
         },
         completed: %{
           issues: completed_issues,
           points: completed_points
         },
         started_at: start_time,
         ended_at: end_time
       }}
    else
      error ->
        error
    end
  end

  defp calculate_end_time(start_time, sprint_length_in_days) do
    end_time =
      start_time
      |> DateTime.to_date()
      |> Date.add(sprint_length_in_days)
      |> Date.to_iso8601()

    end_time = end_time <> "T00:00:00Z"
    {:ok, end_time, _} = DateTime.from_iso8601(end_time)

    end_time
  end

  defp process_issues(issues) do
    issues
    |> Enum.map(fn %{
                     "number" => number,
                     "title" => title,
                     "labels" => labels,
                     "closed_at" => closed_at,
                     "updated_at" => updated_at
                   } ->
      closed_at =
        if is_nil(closed_at) do
          nil
        else
          {:ok, closed_at, _} = DateTime.from_iso8601(closed_at)
          closed_at
        end

      {:ok, updated_at, _} = DateTime.from_iso8601(updated_at)

      %{
        number: number,
        title: title,
        points: get_points(labels),
        labels: process_labels(labels),
        closed: closed_at != nil,
        closed_at: closed_at,
        updated_at: updated_at
      }
    end)
  end

  defp process_labels(labels) do
    Enum.map(labels, fn %{"name" => name} -> name end)
  end

  defp get_points(labels) do
    labels
    |> Enum.find(%{"name" => "points:0"}, fn %{"name" => name} ->
      String.starts_with?(name, "points")
    end)
    |> Map.get("name")
    |> String.split(":")
    |> List.last()
    |> String.to_integer()
  end

  defp accumulate_points(issues) do
    Enum.reduce(issues, 0, fn %{points: points}, acc -> acc + points end)
  end

  defp get_issues_in_milestone(owner, repo, milestone_number) do
    {:ok, issues} =
      Integrations.github().repo_issues(owner, repo, %{
        "state" => "all",
        "milestone" => milestone_number,
        "per_page" => 100
      })

    issues = process_issues(issues)
    points = accumulate_points(issues)

    {:ok, %{issues: issues, points: points}}
  end

  def repo_events_in_sprint(owner, repo, start_time, end_time) do
    iso_start_time = DateTime.to_iso8601(start_time)

    case paged_repo_events([], 1, owner, repo, iso_start_time) do
      {:ok, events} ->
        events =
          events
          |> only_relevant_events(start_time, end_time)
          # Will need them in descending order for next step
          |> Enum.reverse()

        {:ok, events}

      error ->
        error
    end
  end

  defp paged_repo_events([], 1, owner, repo, iso_start_time) do
    case Integrations.github().repo_events(owner, repo, %{per_page: 100, page: 1}) do
      {:ok, events} ->
        if pull_more_events?(events, iso_start_time) do
          paged_repo_events(events, 2, owner, repo, iso_start_time)
        else
          {:ok, events}
        end

      error ->
        error
    end
  end

  defp paged_repo_events(pulled_events, page, owner, repo, iso_start_time) do
    case Integrations.github().repo_events(owner, repo, %{per_page: 100, page: page}) do
      {:ok, events} ->
        if pull_more_events?(events, iso_start_time) do
          paged_repo_events(pulled_events ++ events, page + 1, owner, repo, iso_start_time)
        else
          {:ok, pulled_events ++ events}
        end

      error ->
        error
    end
  end

  defp pull_more_events?(events, iso_start_time) do
    last_event = List.last(events)

    cond do
      is_nil(last_event) ->
        false

      last_event["created_at"] < iso_start_time ->
        false

      true ->
        true
    end
  end

  defp only_relevant_events(events, start_time, end_time) do
    events
    |> Enum.filter(fn %{"created_at" => created_at} ->
      {:ok, created_at, _} = DateTime.from_iso8601(created_at)

      DateTime.compare(end_time, created_at) == :gt and
        DateTime.compare(start_time, created_at) == :lt
    end)
    |> Enum.filter(fn
      %{"event" => "labeled", "label" => %{"name" => name}}
      when name in ["uat", "done"] ->
        true

      %{"event" => "closed"} ->
        true

      _ ->
        false
    end)
  end

  defp issues_from_relevent_events(events) do
    events
    |> Enum.reduce(%{}, fn %{"issue" => issue}, acc ->
      Map.put(acc, issue["number"], issue)
    end)
    |> Map.values()
  end
end
