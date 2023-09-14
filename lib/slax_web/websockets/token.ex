defmodule SlaxWeb.Token do
  @moduledoc """
  A module that handles Slack websocket payloads for token interactions and
  builds modal views for slack https://api.slack.com/reference/surfaces/views
  """

  alias Slax.Projects
  alias Slax.ProjectRepos
  alias Slax.Slack
  alias Slax.Github

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "shortcut",
        "callback_id" => "access_token"
      }) do
    view = build_token_view()

    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "block_actions",
        "view" => %{
          "root_view_id" => view_id
        }
      }) do
    view = build_repo_view()

    Slack.update_modal(%{trigger_id: trigger_id, view: view, view_id: view_id})
  end

  def handle_payload(%{
        "trigger_id" => _trigger_id,
        "type" => "view_submission",
        "view" => %{
          "callback_id" => "token_view",
          "state" => %{
            "values" => values
          }
        }
      }) do
    with %{
           "repos_select" => %{"selected_options" => repos_options},
           "token_input" => %{"value" => token},
           "expiration_datepicker" => %{"selected_date" => expiration_date}
         } <- parse_state_values(values),
         {:ok, date} <- Date.from_iso8601(expiration_date) do
      repos_options
      |> Enum.map(& &1["value"])
      |> ProjectRepos.add_token_to_repos(token, date)
    end

    :ok
  end

  def handle_payload(%{
        "trigger_id" => _trigger_id,
        "type" => "view_submission",
        "view" => %{
          "callback_id" => "repo_view",
          "state" => %{
            "values" => values
          }
        }
      }) do
    with %{
           "project_name_input" => %{"value" => nil},
           "repo_name_input" => repo_name_input,
           "project_select" => project_select
         } <-
           parse_state_values(values) do
      # don't create project, create repo and attach it to project
      {org_name, repo_name} = Github.parse_repo_org(repo_name_input["value"])

      ProjectRepos.create(%{
        org_name: org_name,
        repo_name: repo_name,
        project_id: String.to_integer(project_select["selected_option"]["value"])
      })
    else
      %{
        "project_name_input" => %{"value" => project_name},
        "repo_name_input" => repo_name_input,
        "project_select" => _project_select
      } ->
        # create project with project name, create repo and attach it to project
        {org_name, repo_name} = Github.parse_repo_org(repo_name_input["value"])

        ProjectRepos.create_repo_with_project(%{
          project_name: project_name,
          org_name: org_name,
          repo_name: repo_name
        })
    end

    build_token_view()
  end

  defp parse_state_values(values) do
    values
    |> Map.values()
    |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)
  end

  defp build_token_view() do
    project_repos =
      case ProjectRepos.get_all() do
        [] ->
          [%{org_name: "example", repo_name: "example", id: "example"}]

        project_repos ->
          project_repos
      end

    %{
      type: "modal",
      callback_id: "token_view",
      submit: %{
        type: "plain_text",
        text: "Submit"
      },
      title: %{
        type: "plain_text",
        text: "Example Modal"
      },
      blocks: [
        %{
          type: "input",
          element: %{
            type: "multi_static_select",
            action_id: "repos_select",
            placeholder: %{
              type: "plain_text",
              text: "Select a Repo",
              emoji: true
            },
            options:
              Enum.map(project_repos, fn repo ->
                %{
                  text: %{type: "plain_text", text: "#{repo.org_name}/#{repo.repo_name}"},
                  value: "#{repo.id}"
                }
              end)
          },
          label: %{
            type: "plain_text",
            text: "Repos",
            emoji: true
          }
        },
        %{
          type: "actions",
          elements: [
            %{
              type: "button",
              text: %{
                type: "plain_text",
                text: "Create Repo",
                emoji: false
              },
              value: "create_repo",
              action_id: "actionID-0"
            }
          ]
        },
        %{
          type: "input",
          element: %{
            type: "plain_text_input",
            action_id: "token_input",
            placeholder: %{
              type: "plain_text",
              text: "Github fine-grained access token"
            }
          },
          label: %{
            type: "plain_text",
            text: "Access Token",
            emoji: true
          }
        },
        %{
          type: "input",
          element: %{
            type: "datepicker",
            initial_date: Date.to_iso8601(DateTime.utc_now()),
            placeholder: %{
              type: "plain_text",
              text: "Select a date",
              emoji: true
            },
            action_id: "expiration_datepicker"
          },
          label: %{
            type: "plain_text",
            text: "Token Expiration Date",
            emoji: true
          }
        }
      ]
    }
  end

  defp build_repo_view() do
    projects =
      case Projects.get_all() do
        [] ->
          [%{name: "example", id: "example"}]

        projects ->
          projects
      end

    %{
      type: "modal",
      callback_id: "repo_view",
      submit: %{
        type: "plain_text",
        text: "Submit"
      },
      title: %{
        type: "plain_text",
        text: "Example Modal"
      },
      blocks: [
        %{
          type: "input",
          optional: true,
          element: %{
            type: "static_select",
            action_id: "project_select",
            placeholder: %{
              type: "plain_text",
              text: "Select a Project",
              emoji: true
            },
            options:
              Enum.map(projects, fn project ->
                %{text: %{type: "plain_text", text: project.name}, value: "#{project.id}"}
              end)
          },
          label: %{
            type: "plain_text",
            text: "Projects",
            emoji: true
          }
        },
        %{
          type: "input",
          optional: true,
          element: %{
            type: "plain_text_input",
            action_id: "project_name_input",
            placeholder: %{
              type: "plain_text",
              text: "project"
            }
          },
          label: %{
            type: "plain_text",
            text: "Project Name",
            emoji: true
          }
        },
        %{
          type: "input",
          element: %{
            type: "plain_text_input",
            action_id: "repo_name_input",
            placeholder: %{
              type: "plain_text",
              text: "org/repo"
            }
          },
          label: %{
            type: "plain_text",
            text: "Repo Name",
            emoji: true
          }
        }
      ]
    }
  end
end
