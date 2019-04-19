defmodule Slax.GithubCommands.Test do
    use Slax.ModelCase, async: true
    alias Slax.Commands.GithubCommands
    
    test "format_issues/1" do
        assert GithubCommands.format_issues([%{"title" => "title", "updated_at" => "2019-04-18T14:08:35Z", "labels"=> [%{"name" => "in progress"}]}]) =~ "Last Updated at"
    end
  end