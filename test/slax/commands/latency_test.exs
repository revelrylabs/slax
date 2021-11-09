defmodule Slax.Latency.Test do
  use Slax.ModelCase, async: true
  alias Slax.Commands.Latency

  test "format_response/1" do
    {:ok, long_time_ago} = DateTime.from_unix(0)

    formatted =
      Latency.format_response([
        %{
          "title" => "title",
          "updated_at" => "2019-04-18T14:08:35Z",
          "labels" => [%{"name" => "in progress"}],
          "assignees" => [],
          "events" => [
            %{
              "action" => "labeled",
              "label" => %{"name" => "in progress"},
              "created_at" => long_time_ago |> DateTime.to_iso8601()
            }
          ]
        }
      ])

    assert formatted =~ "Last Updated"
    assert formatted =~ "title"
  end
end
