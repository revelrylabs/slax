defmodule Slax.ProjectRepos.Test do
  use Slax.ModelCase, async: true
  alias Slax.{ProjectRepos, Projects}

  setup do
    project = insert(:project)
    project_repo = insert(:project_repo, project: project)
    project_channel = insert(:project_channel, project: project, blockerbot_on: true)

    # load associations
    project = Projects.get_project_for_channel(project_channel.channel_name)

    [project: project, project_channel: project_channel, project_repo: project_repo]
  end

  describe "get all repos for blockerbot" do
    test "get_blockerbot_repos/0 with a single repo" do
      [repo] = ProjectRepos.get_blockerbot_repos()

      assert repo.org_name == "milivanili"
      assert repo.repo_name == "girl u know its true"
      assert repo.channel_name == "testchannel"
    end

    test "get_blockerbot_repos/0 with multiple repos", %{project: project} do
      _repo2 = insert(:project_repo, project: project, repo_name: "second one")
      repos = ProjectRepos.get_blockerbot_repos()

      assert length(repos) == 2
    end
  end

  describe "get all repos by token" do
    test "get_all_with_token/0" do
      repos_with_token = ProjectRepos.get_all_with_token()
      assert length(repos_with_token) == 1
    end
  end
end
