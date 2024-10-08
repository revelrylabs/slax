defmodule Slax.ProjectRepos do
  @moduledoc false
  use Slax.Context

  alias Slax.{ProjectRepo, ProjectChannel, Projects}
  alias Ecto.Multi
  alias Ecto.Query

  def get_blockerbot_repos() do
    ProjectRepo
    |> join(:left, [pr], pc in ProjectChannel, on: pr.project_id == pc.project_id)
    |> where([pr, pc], pc.blockerbot_on)
    |> select([pr, pc], %{
      repo_name: pr.repo_name,
      org_name: pr.org_name,
      channel_name: pc.channel_name
    })
    |> Repo.all()
  end

  def create(repo) do
    repo
    |> ProjectRepo.changeset()
    |> Repo.insert()
  end

  def create_repo_with_project(%{
        project_name: project_name,
        org_name: org_name,
        repo_name: repo_name
      }) do
    Multi.new()
    |> Multi.run(:project, fn _, _ ->
      Projects.get_or_create_by_name(project_name)
    end)
    |> Multi.insert(
      :repo,
      &ProjectRepo.changeset(%{
        org_name: org_name,
        repo_name: repo_name,
        project_id: &1.project.id
      })
    )
    |> Repo.transaction()
  end

  def add_token_to_repos(repo_ids, token, expiration_date) do
    repo_ids
    |> Enum.reduce(Multi.new(), fn id, multi ->
      Multi.update(
        multi,
        {:project_repo, id},
        ProjectRepo.token_changeset(Repo.get(ProjectRepo, id), token, expiration_date)
      )
    end)
    |> Repo.transaction()
  end

  def get(id, preloads \\ []) do
    ProjectRepo
    |> Repo.get(id)
    |> Repo.preload(preloads)
  end

  def get_all() do
    Repo.all(ProjectRepo)
  end

  def get_all_with_token() do
    ProjectRepo
    |> Query.where([pr], not is_nil(pr.token))
    |> Repo.all()
  end

  def get_by_repo_and_org(repo_name, org_name) do
    lower_repo_name = String.downcase(repo_name)
    lower_org_name = String.downcase(org_name)

    query =
      from(
        p in ProjectRepo,
        where:
          fragment("lower(?)", p.repo_name) == ^lower_repo_name and
            fragment("lower(?)", p.org_name) == ^lower_org_name
      )

    Repo.one(query)
  end

  def list_needs_reminder_message() do
    now = DateTime.utc_now()
    threshold = Timex.shift(now, days: 3)

    query =
      from(r in ProjectRepo,
        where: r.expiration_date <= ^threshold and r.expiration_date >= ^now
      )

    Repo.all(query)
  end
end
