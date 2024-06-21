defmodule SlaxWeb.DefaultRepo do
  @moduledoc """
  A module that handles Slack websocket payloads for setting default channel repos
  and builds modal views for slack https://api.slack.com/reference/surfaces/views
  """

  alias Slax.{Channels, ProjectRepos}
  alias Slax.Slack

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "shortcut",
        "callback_id" => "set_default_repo"
      }) do
    view = build_default_repo_view()

    Slack.open_modal(%{trigger_id: trigger_id, view: view})
  end

  def handle_payload(%{
        "trigger_id" => trigger_id,
        "type" => "view_submission",
        "view" => %{
          "callback_id" => "default_repo_view",
          "state" => %{
            "values" => values
          }
        }
      }) do
    with %{
           "repo_select" => %{"selected_option" => %{"value" => selected_repo}},
           "channels_select_action" => %{"selected_channel" => channel_id}
         } <- parse_state_values(values) do
      slack_channel =
        %{trigger_id: trigger_id}
        |> Slack.get_channels()
        |> Enum.find(&(&1["id"] == channel_id))

      Channels.set_default_repo(slack_channel, %{default_project_repo_id: selected_repo})
    end

    :ok
  end

  defp build_default_repo_view() do
    project_repos =
      case ProjectRepos.get_all_with_token() do
        [] ->
          [%{org_name: "example", repo_name: "example", id: "example"}]

        project_repos ->
          project_repos
      end

    %{
      type: "modal",
      callback_id: "default_repo_view",
      submit: %{
        type: "plain_text",
        text: "Submit"
      },
      title: %{
        type: "plain_text",
        text: "Set Default Channel Repo"
      },
      blocks: [
        %{
          type: "input",
          block_id: "channel",
          element: %{
            type: "channels_select",
            placeholder: %{
              type: "plain_text",
              text: "Select channel",
              emoji: true
            },
            action_id: "channels_select_action"
          },
          label: %{
            type: "plain_text",
            text: "Select Channel",
            emoji: true
          }
        },
        %{
          type: "input",
          element: %{
            type: "static_select",
            action_id: "repo_select",
            placeholder: %{
              type: "plain_text",
              text: "Select default repo",
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
            text: "Select Default Repo",
            emoji: true
          }
        }
      ]
    }
  end

  defp parse_state_values(values) do
    values
    |> Map.values()
    |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)
  end
end
