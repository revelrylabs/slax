defmodule Slax.Sprints do
  @moduledoc """
  Set sprint commitments and check their status
  """

  use Slax.Context

  alias Slax.{ProjectRepo, Sprint}

  @doc """
  Create a new sprint commitment based on a list of GitHub issue numbers
  """
  def create_sprint_commitment(%{repo: _, issue_numbers: _, user: _, week: _} = params) do
    params
    |> validate_issues()
    |> find_or_create_milestone()
    |> add_issues_to_milestone()
    |> get_or_create_sprint()
  end

  @doc """
  Make sure a list of issues actually exists for a repo
  """
  def validate_issues(%{repo: repo, issue_numbers: issue_numbers, user: user} = params) do
    repo = "#{repo.org_name}/#{repo.repo_name}"

    issue_numbers
    |> Enum.reduce({:ok, [], nil}, fn number, {_, messages, _} = acc ->
      %{repo: repo, number: number, access_token: user.github_access_token}
      |> Github.fetch_issue()
      |> case do
        %{"message" => "Not Found"} ->
          {:error, messages ++ ["Issue #{number} could not be found"], params}

        %{"id" => _} ->
          {:ok, messages, params}
      end
    end)
  end

  @doc """
  If a milestone for a week isn't found, create one unless there was a previous
  error in the workflow then skip this step
  """
  def find_or_create_milestone({:error, _, _} = params), do: params

  def find_or_create_milestone(
        {:ok, _, %{repo: repo, issue_numbers: issue_numbers, week: week, user: user} = params}
      ) do
    repo = "#{repo.org_name}/#{repo.repo_name}"
    milestone_title = "Week #{week}"

    milestone_description =
      issue_numbers
      |> Enum.map(fn issue_number ->
        "##{issue_number}"
      end)
      |> List.insert_at(0, "Milestone created by #{user.github_username}")
      |> Enum.join("\n")

    case find_milestone_by_title(repo, milestone_title, user) do
      nil ->
        # Create the milestone
        {:ok, milestone} =
          Github.create_milestone(%{
            repo: repo,
            access_token: user.github_access_token,
            title: milestone_title,
            description: milestone_description
          })

        {:ok, Map.get(milestone, "number"), params}

      milestone ->
        {:ok, Map.get(milestone, "number"), params}

      {:error, _} ->
        {:error, "Could not fetch milestones for the repo", params}
    end
  end

  @doc """
  Search through all milestones for a repo to find one with a matching title

  Note: This downloads all milestones for a repo and can be slow
  """
  def find_milestone_by_title(repo, title, user) do
    Github.fetch_milestones(%{
      repo: repo,
      access_token: user.github_access_token
    })
    |> case do
      {:ok, milestones} ->
        Enum.find(milestones, &(Map.get(&1, "title") == title))

      {:error, _} ->
        {:error, "Could not fetch milestones for the repo"}
    end
  end

  @doc """
  Add issues (one at a time unfortunately) to a milestone
  """
  def add_issues_to_milestone({:error, _, _} = params), do: params

  def add_issues_to_milestone(
        {:ok, milestone_number, %{repo: repo, issue_numbers: issue_numbers, user: user}} = params
      ) do
    repo = "#{repo.org_name}/#{repo.repo_name}"

    issue_numbers
    |> Enum.each(fn number ->
      %{
        repo: repo,
        issue_number: number,
        milestone_number: milestone_number,
        access_token: user.github_access_token
      }
      |> Github.add_issue_to_milestone()
    end)

    params
  end

  @doc """
  Create a sprint in the db if it doesn't exist already
  """
  def get_or_create_sprint({:error, _, _} = params), do: params

  def get_or_create_sprint(
        {:ok, milestone_number, %{repo: repo, issue_numbers: issue_numbers}} = params
      ) do
    Sprint
    |> where([s], s.project_repo_id == ^repo.id and s.milestone_id == ^milestone_number)
    |> Repo.one()
    |> case do
      nil ->
        create_sprint(%{
          issues: issue_numbers,
          project_repo_id: repo.id,
          milestone_id: milestone_number
        })

      _ ->
        nil
    end

    params
  end

  @doc """
  Create a sprint in the db
  """
  def create_sprint(attrs \\ %{}) do
    %Sprint{}
    |> Sprint.changeset(attrs)
    |> Repo.insert()
  end
end
