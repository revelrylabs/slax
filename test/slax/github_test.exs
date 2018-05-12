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
end
