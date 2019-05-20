defmodule Slax.Commands.NewProjectTest do
  use Slax.ModelCase, async: true
  import Mox

  @subject Slax.Commands.NewProject

  def response(text, status, response) do
    fn path, _, _ ->
      assert String.contains?(path, text)

      {:ok,
       %HTTPoison.Response{
         status_code: status,
         body: response
       }}
    end
  end

  def post_response(text, status, response) do
    fn path, body, _, _ ->
      assert String.contains?(path, text) || String.contains?(body, text)

      {:ok,
       %HTTPoison.Response{
         status_code: status,
         body: response
       }}
    end
  end

  def successful_create_reusable_stories(results, _,_,_,_) do
    results
    |> put_in([:resuseable_stories], true)
    |> put_in([:success, :resuseable_stories], "Reuseable Stories Created")
  end

  def failing_create_reusable_stories(results, _,_,_,_), do: results

  describe "new_project/6" do
    test "when all args are valid and all requests work and the repo hasn't been created yet" do
      alias Slax.Commands.{GithubCommandsMock, GithubCommands}

      # validate the project_name
      expect(GithubCommandsMock, :parse_project_name, 1, &GithubCommands.parse_project_name/2)

      # we can't find the repo so it doesn't exist yet
      expect(
        Slax.HttpMock,
        :get,
        1,
        response("project_name", 404, ~S<{ "message": "not found" }>)
      )

      # we create the repo
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response("project_name", 200, ~S<{ "html_url": "project_url" }>)
      )

      # add all reusable stories from the story_repo
      expect(Slax.Commands.GithubCommandsMock, :create_reusable_stories, 1, &successful_create_reusable_stories/5)

      # create slack channel
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response(
          "project_name",
          200,
          ~S<{ "ok": true, "channel": { "id": "1", "name": "project_name" } }>
        )
      )

      # add the teams push permission to the github repo
      expect(Slax.HttpMock, :put, 1, post_response("org_team1", 200, ~S<>))
      expect(Slax.HttpMock, :put, 1, post_response("org_team2", 200, ~S<>))

      # webhooks
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "1"}>))
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "2"}>))

      result =
        @subject.new_project(
          "org_name",
          "project_name",
          "access_token",
          "story_repo",
          "story_paths",
          "org_team1,org_team2"
        )

      assert result[:errors] == %{}
      assert result[:project_name] == "project_name"
      assert result[:github_repo] == "project_url"
      assert result[:slack_channel] == "project_name"
      assert result[:lintron] == true
      assert result[:board_checker] == true
      assert result[:github_org_teams] == true
      assert result[:resuseable_stories] == true

      assert result[:success] == %{
               board_checker: "Board Checker Created",
               github_org_teams: "Github Teams Added",
               github_repo: "Github Repo Found or Created: <project_url>",
               lintron: "Lintron Created",
               project_name: "Project Name Parsed",
               slack_channel: "Channel Created: <#1|project_name>",
               resuseable_stories: "Reuseable Stories Created"
             }
    end

    test "when creating the github repo fails" do
      alias Slax.Commands.{GithubCommandsMock, GithubCommands}

      # validate the project_name
      expect(GithubCommandsMock, :parse_project_name, 1, &GithubCommands.parse_project_name/2)

      # we can't find the repo so it doesn't exist yet
      expect(
        Slax.HttpMock,
        :get,
        1,
        response("project_name", 404, ~S<{ "message": "not found" }>)
      )

      # we fail at creating the repo
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response("project_name", 500, ~S<{ "message": "no repo for you!" }>)
      )


      # we can't create any reusable stories
      expect(Slax.Commands.GithubCommandsMock, :create_reusable_stories, 1, &failing_create_reusable_stories/5)

      # create slack channel
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response(
          "project_name",
          200,
          ~S<{ "ok": true, "channel": { "id": "1", "name": "project_name" } }>
        )
      )

      result =
        @subject.new_project(
          "org_name",
          "project_name",
          "access_token",
          "story_repo",
          "story_paths",
          "org_team1,org_team2"
        )

      assert result[:errors] == %{ github_repo: "no repo for you!"}

      assert result[:project_name] == "project_name"
      assert result[:github_repo] == nil
      assert result[:slack_channel] == "project_name"
      assert result[:lintron] == nil
      assert result[:board_checker] == nil
      assert result[:github_org_teams] == nil
      assert result[:resuseable_stories] == nil

      assert result[:success] == %{
               project_name: "Project Name Parsed",
               slack_channel: "Channel Created: <#1|project_name>",
             }
    end

    test "when the project name is not valid" do
      alias Slax.Commands.{GithubCommandsMock, GithubCommands}

      # validate the project_name
      expect(GithubCommandsMock, :parse_project_name, 1, &GithubCommands.parse_project_name/2)

      # we can't create any reusable stories
      expect(Slax.Commands.GithubCommandsMock, :create_reusable_stories, 1, &failing_create_reusable_stories/5)

      result =
        @subject.new_project(
          "org_name",
          "$project_name&",
          "access_token",
          "story_repo",
          "story_paths",
          "org_team1,org_team2"
        )

      assert result[:errors] == %{ project_name: "Invalid Project Name"}
      assert result[:project_name] == nil
      assert result[:github_repo] == nil
      assert result[:slack_channel] == nil
      assert result[:lintron] == nil
      assert result[:board_checker] == nil
      assert result[:github_org_teams] == nil
      assert result[:resuseable_stories] == nil
      assert result[:success] == %{}
    end

    test "when creating the slack channel fails" do
      alias Slax.Commands.{GithubCommandsMock, GithubCommands}

      # validate the project_name
      expect(GithubCommandsMock, :parse_project_name, 1, &GithubCommands.parse_project_name/2)

      # we can't find the repo so it doesn't exist yet
      expect(
        Slax.HttpMock,
        :get,
        1,
        response("project_name", 404, ~S<{ "message": "not found" }>)
      )

      # we create the repo
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response("project_name", 200, ~S<{ "html_url": "project_url" }>)
      )

      # add all reusable stories from the story_repo
      expect(Slax.Commands.GithubCommandsMock, :create_reusable_stories, 1, &successful_create_reusable_stories/5)

      # create slack channel
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response(
          "project_name",
          400,
          ~S<{ "error": "no channel" }>
        )
      )

      # add the teams push permission to the github repo
      expect(Slax.HttpMock, :put, 1, post_response("org_team1", 200, ~S<>))
      expect(Slax.HttpMock, :put, 1, post_response("org_team2", 200, ~S<>))

      # webhooks
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "1"}>))
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "2"}>))

      result =
        @subject.new_project(
          "org_name",
          "project_name",
          "access_token",
          "story_repo",
          "story_paths",
          "org_team1,org_team2"
        )

      assert result[:errors] == %{ slack_channel: "no channel" }
      assert result[:project_name] == "project_name"
      assert result[:github_repo] == "project_url"
      assert result[:slack_channel] == nil
      assert result[:lintron] == true
      assert result[:board_checker] == true
      assert result[:github_org_teams] == true
      assert result[:resuseable_stories] == true
      assert result[:success] == %{
        resuseable_stories: "Reuseable Stories Created",
        board_checker: "Board Checker Created",
        github_org_teams: "Github Teams Added",
        github_repo: "Github Repo Found or Created: <project_url>",
        lintron: "Lintron Created",
        project_name: "Project Name Parsed"
      }
    end

    test "adding the org teams fails" do
      alias Slax.Commands.{GithubCommandsMock, GithubCommands}

      # validate the project_name
      expect(GithubCommandsMock, :parse_project_name, 1, &GithubCommands.parse_project_name/2)

      # we can't find the repo so it doesn't exist yet
      expect(
        Slax.HttpMock,
        :get,
        1,
        response("project_name", 404, ~S<{ "message": "not found" }>)
      )

      # we create the repo
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response("project_name", 200, ~S<{ "html_url": "project_url" }>)
      )

      # add all reusable stories from the story_repo
      expect(Slax.Commands.GithubCommandsMock, :create_reusable_stories, 1, &successful_create_reusable_stories/5)

      # create slack channel
      expect(
        Slax.HttpMock,
        :post,
        1,
        post_response(
          "project_name",
          200,
          ~S<{ "ok": true, "channel": { "id": "1", "name": "project_name" } }>
        )
      )

      # add the teams push permission to the github repo
      expect(Slax.HttpMock, :put, 1, post_response("org_team1", 400, ~S<{ "message": "you done goofed" }>))
      expect(Slax.HttpMock, :put, 1, post_response("org_team2", 400, ~S<{ "message": "you done goofed" }>))

      # webhooks
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "1"}>))
      expect(Slax.HttpMock, :post, 1, post_response("project_name", 200, ~S<{ "id": "2"}>))

      result =
        @subject.new_project(
          "org_name",
          "project_name",
          "access_token",
          "story_repo",
          "story_paths",
          "org_team1,org_team2"
        )

      assert result[:errors] == %{ github_org_teams: "org_team1: you done goofed\norg_team2: you done goofed" }
      assert result[:project_name] == "project_name"
      assert result[:github_repo] == "project_url"
      assert result[:slack_channel] == "project_name"
      assert result[:lintron] == true
      assert result[:board_checker] == true
      assert result[:github_org_teams] == nil
      assert result[:resuseable_stories] == true
      assert result[:success] == %{
        resuseable_stories: "Reuseable Stories Created",
        slack_channel: "Channel Created: <#1|project_name>",
        board_checker: "Board Checker Created",
        github_repo: "Github Repo Found or Created: <project_url>",
        lintron: "Lintron Created",
        project_name: "Project Name Parsed"
      }
    end
  end
end
