defmodule Slax.TenThousandFeet.Test do
  use Slax.ModelCase, async: true
  alias Slax.TenThousandFeet

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.TenThousandFeet,
      api_endpoint: url,
      auth_token: "token"
    )

    {:ok, bypass: bypass}
  end

  test "create_project/1 when TenThousandFeet not configured" do
    Application.put_env(:slax, Slax.TenThousandFeet, [])

    assert {:error, "10000ft not configured"} = TenThousandFeet.create_project("blah")
  end

  test "create_project/1 when there is a failure", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/projects", fn conn ->
      Plug.Conn.resp(conn, 400, ~s<{"message": "Something happened"}>)
    end)

    assert {:error, "Something happened"} = TenThousandFeet.create_project("blah")
  end

  test "create_project/1 when there is success", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/projects", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"message": "success"}>)
    end)

    assert :ok = TenThousandFeet.create_project("blah")
  end
end
