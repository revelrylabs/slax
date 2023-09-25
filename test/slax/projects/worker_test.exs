defmodule Slax.Projects.Worker.Test do
  use Slax.ModelCase, async: true
  use Oban.Testing, repo: Slax.Repo

  import Mox

  alias Slax.ProjectRepos.Worker

  describe "perform/1" do
    test "token expiring within 3 days, reminder job success" do
      now = DateTime.utc_now()

      repo1 =
        insert(:project_repo,
          org_name: "org1",
          repo_name: "repo1",
          expiration_date: Timex.shift(now, days: 3)
        )

      insert(:project_repo,
        org_name: "org2",
        repo_name: "repo2",
        expiration_date: Timex.shift(now, days: 3)
      )

      repo3 =
        insert(:project_repo,
          org_name: "org3",
          repo_name: "repo3",
          expiration_date: Timex.shift(now, days: 2)
        )

      expiration1 = Timex.format!(repo1.expiration_date, "{M}-{D}-{YYYY}")
      expiration3 = Timex.format!(repo3.expiration_date, "{M}-{D}-{YYYY}")

      string3 =
        "token=token&text=Access+token%28s%29+for+the+following+repos+will+expire+on+#{expiration3}%3A+%60org3%2Frepo3%60.+Please+replace+them+using+the+%2Ftoken+command&channel=&unfurl_links=false&unfurl_media=false"

      string1 =
        "token=token&text=Access+token%28s%29+for+the+following+repos+will+expire+on+#{expiration1}%3A+%60org1%2Frepo1%60+%60org2%2Frepo2%60.+Please+replace+them+using+the+%2Ftoken+command&channel=&unfurl_links=false&unfurl_media=false"

      expect(Slax.HttpMock, :post, fn _, ^string3, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      expect(Slax.HttpMock, :post, fn _, ^string1, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      perform_job(Worker, %{})
    end

    test "token expiring today, reminder job success" do
      insert(:project_repo,
        org_name: "org1",
        repo_name: "repo1"
      )

      insert(:project_repo,
        org_name: "org2",
        repo_name: "repo2"
      )

      expect(Slax.HttpMock, :post, fn _,
                                      "token=token&text=Access+token%28s%29+for+the+following+repos+are+expired%3A+%60org1%2Frepo1%60+%60org2%2Frepo2%60.+Please+replace+them+using+the+%2Ftoken+command&channel=&unfurl_links=false&unfurl_media=false",
                                      _,
                                      _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      perform_job(Worker, %{})
    end

    test "token expired before today, no reminder" do
      now = DateTime.utc_now()

      insert(:project_repo,
        org_name: "org1",
        repo_name: "repo1",
        expiration_date: Timex.shift(now, days: -3)
      )

      insert(:project_repo,
        org_name: "org2",
        repo_name: "repo2",
        expiration_date: Timex.shift(now, days: -3)
      )

      perform_job(Worker, %{})
    end

    test "token expiring in more than 3 days, no reminder" do
      now = DateTime.utc_now()

      insert(:project_repo,
        org_name: "org1",
        repo_name: "repo1",
        expiration_date: Timex.shift(now, days: 4)
      )

      insert(:project_repo,
        org_name: "org2",
        repo_name: "repo2",
        expiration_date: Timex.shift(now, days: 7)
      )

      perform_job(Worker, %{})
    end
  end
end
