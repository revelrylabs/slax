defmodule Slax.GithubCommands.Test do
  use Slax.ModelCase, async: true
  alias Slax.Commands.GithubCommands
  import Mox

  test "format_issues/1" do
    assert GithubCommands.format_issues([
             %{
               "title" => "title",
               "updated_at" => "2019-04-18T14:08:35Z",
               "labels" => [%{"name" => "in progress"}]
             }
           ]) =~ "Last Updated at"
  end

  describe "parse_project_name/2" do
    def setup_starting_result(context) do
      {:ok,
       context
       |> Map.put(:starting_result, %{errors: %{}, success: %{}})}
    end

    setup :setup_starting_result

    test "invalid characters", %{starting_result: starting_result} do
      with result <- GithubCommands.parse_project_name(starting_result, "hi&") do
        assert Map.get(result, :errors) == %{project_name: "Invalid Project Name"}
        assert Map.get(result, :project_name) == nil
      end
    end

    test "too many characters", %{starting_result: starting_result} do
      with result <-
             GithubCommands.parse_project_name(
               starting_result,
               "thisshouldbemorethantwentytwocharacters"
             ) do
        assert Map.get(result, :errors) == %{project_name: "Invalid Project Name"}
        assert Map.get(result, :project_name) == nil
      end
    end

    test "valid_input", %{starting_result: starting_result} do
      with result <- GithubCommands.parse_project_name(starting_result, "valid_repo_name") do
        assert Map.get(result, :errors) == %{}
        assert Map.get(result, :success) == %{project_name: "Project Name Parsed"}
        assert Map.get(result, :project_name) == "valid_repo_name"
      end
    end
  end

  def setup_starting_result_with_name(context) do
    {:ok,
     context
     |> Map.put(:starting_result, %{errors: %{}, success: %{}})
     |> put_in([:starting_result, :success, :project_name], "Project Name Parsed")
     |> put_in([:starting_result, :project_name], "valid_project_name")}
  end

  def setup_successful_tree_requests(context) do
    {:ok,
     context
     |> Map.put(:starting_result, %{errors: %{}, success: %{}})
     |> put_in([:starting_result, :success, :project_name], "Project Name Parsed")
     |> put_in([:starting_result, :project_name], "valid_project_name")}
  end

  def successful_tree_request(_, _, _) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body: ~s<{
             "tree": [
               {
                 "path": "story_path1.md",
                 "sha": "test_sha",
                 "type": "blob"
               },
               {
                 "path": "story_path3.md",
                 "sha": "test_sha",
                 "type": "blob"
               }

             ]
           }>
     }}
  end

  def successful_blob_request(_, _, _) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body: ~s<{
           "content": "LS0tCnRpdGxlOiB0ZXN0X3RpdGxlCi0tLQp0ZXN0IGNvbnRlbnQK"
         }>
     }}
  end

  def successful_issue_request(_,_,_,_) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body: ~s<{
         "content": ["1"]
       }>
     }}
  end


  describe "create_reusable_stories/5" do
    setup [:setup_starting_result_with_name]

    test "when all requests are successful", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &successful_blob_request/3)
      expect(Slax.HttpMock, :post, 3, &successful_issue_request/4)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{}
      assert result[:project_name] == "valid_project_name"
      assert result[:reusable_stories] == true
      assert result[:success][:reusable_stories] == "Reuseable Stories Created"
    end

    def failing_request(_,_,_) do
      {:ok,
       %HTTPoison.Response{
         status_code: 400,
         body: ~s<{
           "message": "you done goofed"
         }>
       }}
    end
    def failing_request(w,x,y,_), do: failing_request(w,x,y)

    test "when fetching the project tree fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &failing_request/3)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:reusable_stories] == nil
      assert result[:errors] == %{reusable_stories: "you done goofed"}
      assert result[:project_name] == "valid_project_name"
      assert result[:success] == %{project_name: "Project Name Parsed"}
    end

    test "when fetching a blob fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &failing_request/3)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:reusable_stories] == nil

      assert result[:errors] == %{
               reusable_stories:
                 "story_path1.md: you done goofed\nstory_path3.md: you done goofed"
             }

      assert result[:project_name] == "valid_project_name"
      assert result[:success] == %{project_name: "Project Name Parsed"}
    end

    test "when posting issues fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &successful_blob_request/3)
      expect(Slax.HttpMock, :post, 3, &failing_request/4)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:reusable_stories] == nil

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: you done goofed\nstory_path3.md: you done goofed"
      }

      assert result[:project_name] == "valid_project_name"
      assert result[:success] == %{project_name: "Project Name Parsed"}
    end

    def invalid_blob_request(_,_,_) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: ~s<{
           "content": "invalidblob"
         }>
       }}
    end

    test "when decoding a blob fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &invalid_blob_request/3)
      expect(Slax.HttpMock, :post, 3, &successful_issue_request/4)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:reusable_stories] == nil

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: Unable to parse content\nstory_path3.md: Unable to parse content"
      }

      assert result[:project_name] == "valid_project_name"
      assert result[:success] == %{project_name: "Project Name Parsed"}
    end

    def invalid_frontmatter_request(_,_,_) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: ~s<{
           "content": "LS0KaW52YWxpZCBmcm9udG1hdHRlcgpfCm9vcHMK"
         }>
       }}
    end

    test "when parsing issue frontmatter fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &invalid_frontmatter_request/3)
      expect(Slax.HttpMock, :post, 3, &successful_issue_request/4)

      result =
        GithubCommands.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:reusable_stories] == nil

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: invalid_front_matter\nstory_path3.md: invalid_front_matter"
      }

      assert result[:project_name] == "valid_project_name"
      assert result[:success] == %{project_name: "Project Name Parsed"}
    end
  end
end
