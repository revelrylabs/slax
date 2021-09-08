defmodule SlaxWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use SlaxWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  import Slax.Factory
  import Plug.Conn

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import SlaxWeb.ConnCase
      import Slax.Factory
      import Phoenix.LiveViewTest
      use Surface.LiveViewTest

      alias SlaxWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint SlaxWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Slax.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Slax.Repo, {:shared, self()})
    end

    %{user: user} = insert(:team) |> with_user()

    conn =
      Phoenix.ConnTest.build_conn()
      |> assign(:current_user, user)
      |> Plug.Test.init_test_session(%{"user_id" => user.id})


    {:ok, conn: conn}
  end
end
