defmodule Slax.Github.Test do
  use Slax.ModelCase, async: true
  alias Slax.{Github}
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "authorize_url/1" do
    assert Github.authorize_url(%{token: "token"}) =~ "token=token"
  end

  test "fetch_access_token/1" do
    expect(Slax.HttpMock, :post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"access_token": "token"}>}}
    end)

    assert Github.fetch_access_token(%{}) == "token"
  end

  test "current_user_info/1" do
    expect(Slax.HttpMock, :get, fn _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"username": "test"}>}}
    end)

    assert Github.current_user_info(%{}) == %{"username" => "test"}
  end

  def create_issue_setup(context) do
    params = %{
      repo: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:repo]}/issues"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "create_issue/1" do
    setup [:create_issue_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"html_url": "http://github.com"}>}}
      end)

      assert Github.create_issue(params) == {:ok, "http://github.com"}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Something happened"}>}}
      end)

      assert Github.create_issue(params) == {:error, "Something happened"}
    end
  end

  def create_comment_setup(context) do
    params = %{
      body: "comment",
      org: "test",
      repo: "test",
      issue_number: 1,
      access_token: "token"
    }

    url = "/repos/#{params[:org]}/#{params[:repo]}/issues/#{params[:issue_number]}/comments"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "create_comment/1" do
    setup [:create_comment_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"html_url": "http://github.com"}>}}
      end)

      assert Github.create_comment(params) == {:ok, "http://github.com"}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Something happened"}>}}
      end)

      assert Github.create_comment(params) == {:error, "Something happened"}
    end
  end

  def fetch_issues_setup(context) do
    params = %{
      username: "test",
      repo: "test",
      org: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:org]}/#{params[:repo]}/issues"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_issues/1" do
    setup [:fetch_issues_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<[{"id": 1}]>}}
      end)

      assert Github.fetch_issues(params) == [%{"id" => 1, "org" => "test", "repo" => "test"}]
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Something happened"}>}}
      end)

      assert Github.fetch_issues(params) == %{"message" => "Something happened"}
    end
  end

  def fetch_issue_setup(context) do
    params = %{
      username: "test",
      repo: "test",
      access_token: "token",
      number: 1
    }

    url = "/repos/#{params[:repo]}/issues/1"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_issue/1" do
    setup [:fetch_issue_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"id": 1}>}}
      end)

      assert Github.fetch_issue(params) == %{"id" => 1}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Something happened"}>}}
      end)

      assert Github.fetch_issue(params) == %{"message" => "Something happened"}
    end
  end

  def fetch_milestones_setup(context) do
    params = %{
      repo: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:repo]}/milestones"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_milestones/1" do
    setup [:fetch_milestones_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<[{"id": 1}]>}}
      end)

      assert Github.fetch_milestones(params) == {:ok, [%{"id" => 1}]}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 404, body: ~s<{"message": "Not Found"}>}}
      end)

      assert Github.fetch_milestones(params) == {:error, :not_found}
    end
  end

  def create_milestone_setup(context) do
    params = %{
      repo: "test",
      access_token: "token",
      title: "Milestone",
      description: "Something"
    }

    url = "/repos/#{params[:repo]}/milestones"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "create_milestone/1" do
    setup [:create_milestone_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"id": 1}>}}
      end)

      assert Github.create_milestone(params) == {:ok, %{"id" => 1}}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Invalid"}>}}
      end)

      assert Github.create_milestone(params) == {:error, "Invalid"}
    end
  end

  def add_issue_to_milestone_setup(context) do
    params = %{
      repo: "test",
      access_token: "token",
      milestone_number: 1,
      issue_number: 2
    }

    url = "/repos/#{params[:repo]}/issues/#{params[:issue_number]}"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "add_issue_to_milestone/1" do
    setup [:add_issue_to_milestone_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :patch, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"id": 1}>}}
      end)

      assert Github.add_issue_to_milestone(params) == {:ok, %{"id" => 1}}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :patch, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 400, body: ~s<{"message": "Invalid"}>}}
      end)

      assert Github.add_issue_to_milestone(params) == {:error, "Invalid"}
    end
  end

  def create_repo_setup(context) do
    params = %{
      name: "test",
      org_name: "test",
      access_token: "token"
    }

    url = "/orgs/#{params[:org_name]}/repos"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "create_repo/1" do
    setup [:create_repo_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"html_url": "https://github.com/test/test"}>
         }}
      end)

      assert Github.create_repo(params) == {:ok, "https://github.com/test/test"}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.create_repo(params) == {:error, "Invalid"}
    end
  end

  def fetch_repo_setup(context) do
    params = %{
      name: "test",
      org_name: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:org_name]}/#{params[:name]}"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_repo/1" do
    setup [:fetch_repo_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"html_url": "https://github.com/test/test"}>
         }}
      end)

      assert Github.fetch_repo(params) == {:ok, "https://github.com/test/test"}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.fetch_repo(params) == {:error, "Invalid"}
    end

    test "not found", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: ~s<{}>
         }}
      end)

      assert Github.fetch_repo(params) == :not_found
    end
  end

  def create_webhook_setup(context) do
    params = %{
      repo: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:repo]}/hooks"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "create_webhook/1" do
    setup [:create_webhook_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"id": 1}>
         }}
      end)

      assert Github.create_webhook(params) == {:ok, 1}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.create_webhook(params) == {:error, "Invalid"}
    end
  end

  def fetch_tree_setup(context) do
    params = %{
      repo: "test",
      access_token: "token"
    }

    url = "/repos/#{params[:repo]}/git/trees/master"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_tree/1" do
    setup [:fetch_tree_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"html_url": "https://github.com/test/test"}>
         }}
      end)

      assert Github.fetch_tree(params) == {:ok, %{"html_url" => "https://github.com/test/test"}}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.fetch_tree(params) == {:error, "Invalid"}
    end
  end

  def fetch_blob_setup(context) do
    params = %{
      repo: "test",
      sha: "abcdef1234567890",
      access_token: "token"
    }

    url = "/repos/#{params[:repo]}/git/blobs/#{params[:sha]}"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_blob/1" do
    setup [:fetch_blob_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"html_url": "https://github.com/test/test"}>
         }}
      end)

      assert Github.fetch_blob(params) == {:ok, %{"html_url" => "https://github.com/test/test"}}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.fetch_blob(params) == {:error, "Invalid"}
    end
  end

  def list_teams_setup(context) do
    params = %{
      org: "test",
      access_token: "token"
    }

    url = "/orgs/#{params[:org]}/teams"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "list_teams/1" do
    setup [:list_teams_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<[{"id": 1}]>
         }}
      end)

      assert Github.list_teams(params) == {:ok, [%{"id" => 1}]}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.list_teams(params) == {:error, "Invalid"}
    end
  end

  def add_team_to_repo_setup(context) do
    params = %{
      repo: "test",
      team: "test",
      access_token: "token"
    }

    url = "/teams/#{params[:team]}/repos/#{params[:repo]}"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "add_team_to_repo/1" do
    setup [:add_team_to_repo_setup]

    test "success", %{params: params} do
      expect(Slax.HttpMock, :put, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 201,
           body: ~s<{"id": 1}>
         }}
      end)

      assert Github.add_team_to_repo(params) == {:ok, "Created"}
    end

    test "failure", %{params: params} do
      expect(Slax.HttpMock, :put, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"message": "Invalid"}>
         }}
      end)

      assert Github.add_team_to_repo(params) == {:error, "Invalid"}
    end
  end

  def load_issue_setup(context) do
    project = insert(:project)
    insert(:project_repo, project: project, token: "success", repo_name: "success")
    insert(:project_repo, project: project, token: "failure", repo_name: "failure")
    insert(:project_repo, project: project, token: nil, repo_name: "nil")

    params = %{
      repo_and_issue_success: "success/1",
      repo_and_issue_failure: "failure/1",
      repo_and_issue_nil: "nil/1",
      repo_and_issue_na: "na/1"
    }

    {:ok, context |> Map.put(:params, params)}
  end

  describe "load_issue/1" do
    setup [:load_issue_setup]

    test "success", %{params: %{repo_and_issue_success: repo_and_issue}} do
      expect(Slax.Tentacat.IssuesMock, :find, fn _, _, _, _ ->
        {200, %{issue: "success"}, %{}}
      end)

      assert {:ok, %{issue: "success"}, ""} == Github.load_issue(repo_and_issue)
    end

    test "failure: access token invalid", %{params: %{repo_and_issue_failure: repo_and_issue}} do
      expect(Slax.Tentacat.IssuesMock, :find, fn _, _, _, _ ->
        {401, %{"message" => "Bad credentials"}, %{}}
      end)

      assert {:error, "Access token invalid for #{repo_and_issue}"} ==
               Github.load_issue(repo_and_issue)
    end

    test "failure: no access token", %{params: %{repo_and_issue_nil: repo_and_issue}} do
      expect(Slax.Tentacat.IssuesMock, :find, fn _, _, _, _ ->
        {200, %{issue: "success"}, %{}}
      end)

      assert {:ok, %{issue: "success"}, "(Please setup a fine grained access token with /token)"} ==
               Github.load_issue(repo_and_issue)

      # NOTE: remove expect and add back these asserts once the guard is removed and the app no longer uses the generic access token
      # assert {:error, "No access token for #{repo_and_issue}"} ==
      #          Github.load_issue(repo_and_issue)
    end

    test "failure: no project repo", %{params: %{repo_and_issue_na: repo_and_issue}} do
      expect(Slax.Tentacat.IssuesMock, :find, fn _, _, _, _ ->
        {200, %{issue: "success"}, %{}}
      end)

      assert {:ok, %{issue: "success"}, "(Please setup a fine grained access token with /token)"} ==
               Github.load_issue(repo_and_issue)

      # assert {:error, "No project repo set for #{repo_and_issue}"} ==
      #          Github.load_issue(repo_and_issue)
    end
  end
end
