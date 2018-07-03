defmodule Slax.Sprints.CreateCommitmentSaga do
  @moduledoc """
  This module holds all of the steps needed to create a sprint commitment that
  will later be confirmed.

  find_or_create_current_sprint/1 is the main entry point

  It uses Sage for the saga pattern but keeps all CRUD functions in their
  respective contexts
  """

  import Sage

  alias Slax.{Github, Projects, Slack, Sprints}

  def find_or_create_current_commitment(attrs) do
    new()
    |> run(:issue_numbers, &validate_issue_numbers/2)
    |> run(:repo, &get_repo/2, &get_repo_error_handler/4)
    |> run(:milestone, &find_or_create_milestone/2)
    |> run(:current_sprint, &find_or_create_current_sprint/2)
    |> run(:issues, &fetch_issues/2)
    |> run(:sprint_message, &build_sprint_message/2)
    |> run(:update_sprint, &update_sprint/2)
    |> run(:response, &send_response/2)
    |> transaction(Slax.Repo, attrs)
  end

  def validate_issue_numbers(_effects_so_far, %{issue_numbers: issue_numbers}) do
    case issue_numbers do
      [] -> {:error, %{message: "Invalid issue numbers."}}
      _ -> {:ok, issue_numbers}
    end
  end

  def get_repo(_effects_so_far, %{channel_name: channel_name}) do
    {:ok, Projects.get_repo_for_channel(channel_name)}
  end

  def get_repo_error_handler(effect_to_compensate, _, _, _) do
    IO.inspect(effect_to_compensate)
    :abort
  end

  def find_or_create_milestone(%{repo: repo}, %{current_user: user}) do
    {year, week} = :calendar.iso_week_number()

    milestone = Github.fetch_milestones(%{
      state: "all",
      repo: "#{repo.org_name}/#{repo.repo_name}",
      access_token: user.github_access_token
    })
    |> elem(1)
    |> Enum.find(&(&1["title"] == "Week #{week}-#{year}"))
    |> case do
      nil ->
        {:ok, milestone} = Github.create_milestone(%{
          title: "Week #{week}-#{year}",
          repo: "#{repo.org_name}/#{repo.repo_name}",
          access_token: user.github_access_token
        })

        milestone
      milestone ->
        milestone
    end

    {:ok, milestone}
  end

  def find_or_create_current_sprint(%{repo: repo, issue_numbers: issue_numbers, milestone: milestone}, %{channel_name: channel_name, current_user: user}) do
    case Sprints.find_current_sprint_for_channel(channel_name) do
      nil ->
        {year, week} = :calendar.iso_week_number()

        Sprints.create_sprint(%{
          week: week,
          year: year,
          issues: issue_numbers,
          committed: false,
          milestone_id: milestone["number"],
          project_repo_id: repo.id,
          creator_id: user.id
        })

      sprint -> {:ok, sprint}
    end
  end

  def fetch_issues(%{repo: repo}, %{issue_numbers: issue_numbers, current_user: user}) do
    issues =
      Enum.map(issue_numbers, fn issue_number ->
        Github.fetch_issue(%{
          repo: "#{repo.org_name}/#{repo.repo_name}",
          number: issue_number,
          access_token: user.github_access_token
        })
      end)

    {:ok, issues}
  end

  def build_sprint_message(%{current_sprint: sprint, issues: issues, milestone: milestone}, %{additional_message: additional_message}) do
    issue_count = Enum.count(issues)

    point_count =
      Enum.flat_map(issues, fn issue ->
        issue
        |> Map.get("labels", [])
        |> Enum.map(& &1["name"])
      end)
      |> Enum.filter(fn label -> label =~ ~r/points:\d+/ end)
      |> Enum.reduce(0, fn issue, acc ->
        Regex.run(~r/\d+/, issue)
        |> List.first()
        |> String.to_integer()
        |> Kernel.+(acc)
      end)

    sprint_message = """
    *Week #{sprint.week} Sprint Commitment*
    (emoji reaction to confirm @engs @designers @qas @pms)
    _#{issue_count} tickets, #{point_count} points_
    #{milestone["html_url"]}

    #{additional_message}
    """

    {:ok, sprint_message}
  end

  def update_sprint(%{current_sprint: sprint, sprint_message: message, issue_numbers: issue_numbers}, _) do
    Sprints.update_sprint(sprint, %{
      message: message,
      issues: issue_numbers
    })
  end

  def send_response(%{current_sprint: sprint, sprint_message: message}, %{channel_name: channel, response_url: response_url}) do
    Slack.send_message(response_url, %{
      text: """
      You are creating a sprint commitment for week #{sprint.week} for #{channel} with the message below.
      Click one of the buttons to confirm or cancel the commitment
      """,
      attachments: [
        %{
          text: """
          #{message}
          """,
          callback_id: "sprint_commitment",
          actions: [
            %{
              name: "confirm_or_cancel",
              type: "button",
              text: "Confirm commitment",
              value: sprint.id
            },
            %{
              name: "confirm_or_cancel",
              type: "button",
              text: "Cancel",
              value: "cancel"
            }
          ]
        }
      ]
    })

    {:ok, :success}
  end
end
