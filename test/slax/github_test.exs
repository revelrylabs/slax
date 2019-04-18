defmodule Slax.Github.Test do
  use Slax.ModelCase, async: true
  alias Slax.Github

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Github,
      api_url: url,
      oauth_url: url
    )

    {:ok, bypass: bypass}
  end

  test "authorize_url/1" do
    assert Github.authorize_url(%{token: "token"}) =~ "token=token"
  end

  test "fetch_access_token/1", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/access_token", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"access_token": "token"}>)
    end)

    assert Github.fetch_access_token(%{}) == "token"
  end

  test "current_user_info/1", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/user", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"username": "test"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "http://github.com"}>)
      end)

      assert Github.create_issue(params) == {:ok, "http://github.com"}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Something happened"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "http://github.com"}>)
      end)

      assert Github.create_comment(params) == {:ok, "http://github.com"}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Something happened"}>)
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
    

    url = "/repos/#{params[:repo]}/#{params[:repo]}/issues"

    {:ok, context |> Map.put(:params, params) |> Map.put(:url, url)}
  end

  describe "fetch_issues/1" do
    setup [:fetch_issues_setup]

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<[{"id": 1}]>)
      end)

      assert Github.fetch_issues(params) == [%{"id" => 1}]
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Something happened"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"id": 1}>)
      end)

      assert Github.fetch_issue(params) == %{"id" => 1}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Something happened"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<[{"id": 1}]>)
      end)

      assert Github.fetch_milestones(params) == {:ok, [%{"id" => 1}]}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 404, ~s<{"message": "Not Found"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"id": 1}>)
      end)

      assert Github.create_milestone(params) == {:ok, %{"id" => 1}}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "PATCH", url, fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"id": 1}>)
      end)

      assert Github.add_issue_to_milestone(params) == {:ok, %{"id" => 1}}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "PATCH", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "https://github.com/test/test"}>)
      end)

      assert Github.create_repo(params) == {:ok, "https://github.com/test/test"}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "https://github.com/test/test"}>)
      end)

      assert Github.fetch_repo(params) == {:ok, "https://github.com/test/test"}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
      end)

      assert Github.fetch_repo(params) == {:error, "Invalid"}
    end

    test "not found", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 404, ~s<{}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"id": 1}>)
      end)

      assert Github.create_webhook(params) == {:ok, 1}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "https://github.com/test/test"}>)
      end)

      assert Github.fetch_tree(params) == {:ok, %{"html_url" => "https://github.com/test/test"}}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"html_url": "https://github.com/test/test"}>)
      end)

      assert Github.fetch_blob(params) == {:ok, %{"html_url" => "https://github.com/test/test"}}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<[{"id": 1}]>)
      end)

      assert Github.list_teams(params) == {:ok, [%{"id" => 1}]}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "GET", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
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

    test "success", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "PUT", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"id": 1}>)
      end)

      assert Github.add_team_to_repo(params) == {:ok, "Created"}
    end

    test "failure", %{bypass: bypass, params: params, url: url} do
      Bypass.expect_once(bypass, "PUT", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"message": "Invalid"}>)
      end)

      assert Github.add_team_to_repo(params) == {:error, "Invalid"}
    end
  end
end
