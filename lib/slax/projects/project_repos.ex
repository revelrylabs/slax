defmodule Slax.ProjectRepos do
  use Slax.Context

  alias Slax.{ProjectRepo, ProjectChannel, Projects}
  alias Ecto.Multi

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

  def get_by_repo(repo_name) do
    Repo.get_by(ProjectRepo, repo_name: repo_name)
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
