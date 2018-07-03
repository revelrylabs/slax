defmodule Slax.Sprints.ConfirmCommitmentSaga do
  @moduledoc """
  This module holds all of the steps needed to confirm a sprint commitment and
  handle any errors that might occur during the process.

  confirm_sprint_commitment/1 is the main entry point

  It uses Sage for the saga pattern but keeps all CRUD functions in their
  respective contexts
  """

  import Sage

  alias Slax.{Github, Slack, Sprints}

  def confirm_sprint_commitment(attrs) do
    new()
    |> run(:attach_issues, &add_issues_to_milestone/2, &add_issues_to_milestone_error_handler/4)
    |> run(:confirm_commitment, &confirm_commitment/2)
    |> finally(&respond_to_creator/2)
    |> transaction(Slax.Repo, attrs)
  end

  def add_issues_to_milestone(_, %{sprint: sprint}) do
    sprint.issues
    |> Enum.map(fn issue ->
      Github.add_issue_to_milestone(%{
        milestone_number: sprint.milestone_id,
        repo: "#{sprint.project_repo.org_name}/#{sprint.project_repo.repo_name}",
        issue_number: issue,
        access_token: sprint.creator.github_access_token
      })
    end)
    |> Enum.all?(&( match?({:ok, _}, &1) ))
    |> case do
      true -> {:ok, nil}
      false -> {:error, "Could not add all issues to the milestone"}
    end
  end

  def add_issues_to_milestone_error_handler(a, b, c, d) do
    IO.inspect a
    IO.inspect b
    IO.inspect c
    IO.inspect d

    :abort
  end

  def confirm_commitment(_, %{sprint: sprint}) do
    {:ok, Sprints.update_sprint(sprint, %{committed: true})}
  end

  def respond_to_creator(params, %{sprint: sprint, response_url: response_url}) do
    IO.inspect params
    Slack.send_message(response_url, %{
      text: """
      Commitment for Week #{sprint.week} confirmed!
      """
    })

    {:ok, nil}
  end
end
