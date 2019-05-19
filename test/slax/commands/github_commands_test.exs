defmodule Slax.GithubCommands.Test do
  use Slax.ModelCase, async: true
  import Mox
  @subject Slax.Commands.GithubCommands

  describe "format_issues/1" do
    test "when there is an 'in progress' label" do
      assert @subject.format_issues([
               %{
                 "title" => "title",
                 "updated_at" => "2019-04-18T14:08:35Z",
                 "labels" => [%{"name" => "in progress"}]
               }
             ]) =~ "Last Updated at"
    end

    test "when there is not an 'in progress' label" do
      assert @subject.format_issues([
               %{
                 "title" => "title",
                 "updated_at" => "2019-04-18T14:08:35Z",
                 "labels" => [%{"name" => "back log"}]
               }
             ]) =~ ":snail: *Issues In Progress for 5/18* :snail: \n"
    end
  end

  describe "format_results/1" do
    setup :setup_no_errors

    def setup_no_errors(context) do
      {:ok,
       context
       |> Map.put(:starting_result, %{
         project_name: true,
         github_repo: true,
         slack_channel: true,
         errors: %{},
         success: %{
           project_name: "project_name",
           github_repo: "org_name/project_name",
           slack_channel: "slack_channel"
         }
       })}
    end

    test "when there are no errors for any steps", %{starting_result: starting_result} do
      result = @subject.format_results(starting_result)

      assert result ==
               "Project Name: project_name\nGithub: org_name/project_name\nGithub Teams: \nSlack: slack_channel\nLintron: \nBoard Checker: \nReusable Stories: "
    end

    test "when there are errors for certain steps" do
      starting_result = %{
        project_name: true,
        github_repo: true,
        errors: %{
          slack_channel: "slack_channel error"
        },
        success: %{
          project_name: "project_name",
          github_repo: "org_name/project_name"
        }
      }

      result = @subject.format_results(starting_result)

      assert result ==
               "Project Name: project_name\nGithub: org_name/project_name\nGithub Teams: \nSlack: slack_channel error\nLintron: \nBoard Checker: \nReusable Stories: "
    end
  end

  describe "parse_project_name/2" do
    def setup_starting_result(context) do
      {:ok,
       context
       |> Map.put(:starting_result, %{errors: %{}, success: %{}})}
    end

    setup :setup_starting_result

    test "invalid characters", %{starting_result: starting_result} do
      with result <- @subject.parse_project_name(starting_result, "hi&") do
        assert Map.get(result, :errors) == %{project_name: "Invalid Project Name"}
        assert Map.get(result, :project_name) == nil
      end
    end

    test "too many characters", %{starting_result: starting_result} do
      with result <-
             @subject.parse_project_name(
               starting_result,
               "thisshouldbemorethantwentytwocharacters"
             ) do
        assert Map.get(result, :errors) == %{project_name: "Invalid Project Name"}
        assert Map.get(result, :project_name) == nil
      end
    end

    test "valid_input", %{starting_result: starting_result} do
      with result <- @subject.parse_project_name(starting_result, "valid_repo_name") do
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
     |> put_in([:starting_result, :project_name], "valid_project_name")
     |> put_in([:starting_result, :github_repo], "repo_url")
     |> put_in([:starting_result, :success, :github_repo], "Github Repo Found or Created: <repo_url>")
    }
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

  def successful_issue_request(_, _, _, _) do
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
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{}
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == true
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        reusable_stories: "Reuseable Stories Created",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }
    end

    def failing_request(_, _, _) do
      {:ok,
       %HTTPoison.Response{
         status_code: 400,
         body: ~s<{
           "message": "you done goofed"
         }>
       }}
    end

    test "when the starting results dont have a github repo" do
      starting_result =
        %{
          project_name: "valid_project_name",
          errors: %{},
          success: %{
            project_name: "Project Name Parsed"
          }
        }

      result =
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result == starting_result
    end

    def failing_request(w, x, y, _), do: failing_request(w, x, y)

    test "when fetching the project tree fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &failing_request/3)

      result =
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{reusable_stories: "you done goofed"}
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == nil
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }
    end

    test "when fetching a blob fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &failing_request/3)

      result =
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: you done goofed\nstory_path3.md: you done goofed"
      }
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == nil
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }

    end

    test "when posting issues fails", %{starting_result: starting_result} do
      expect(Slax.HttpMock, :get, 1, &successful_tree_request/3)
      expect(Slax.HttpMock, :get, 2, &successful_blob_request/3)
      expect(Slax.HttpMock, :post, 3, &failing_request/4)

      result =
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: you done goofed\nstory_path3.md: you done goofed"
      }
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == nil
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }

    end

    def invalid_blob_request(_, _, _) do
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
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: Unable to parse content\nstory_path3.md: Unable to parse content"
      }
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == nil
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }
    end

    def invalid_frontmatter_request(_, _, _) do
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
        @subject.create_reusable_stories(
          starting_result,
          "access_token",
          "test_org",
          "story_repo",
          path1: "story_path1",
          path3: "story_path3"
        )

      assert result[:errors] == %{
        reusable_stories:
        "story_path1.md: invalid_front_matter\nstory_path3.md: invalid_front_matter"
      }
      assert result[:project_name] == "valid_project_name"
      assert result[:github_repo] == "repo_url"
      assert result[:reusable_stories] == nil
      assert result[:success] == %{
        project_name: "Project Name Parsed",
        github_repo: "Github Repo Found or Created: <repo_url>"
      }
    end
  end
end
