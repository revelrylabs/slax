defmodule TenThousandFeet do
  @api_url Application.get_env(:slax, :ten_thousand_feet)[:api_endpoint]
  @auth_token Application.get_env(:slax, :ten_thousand_feet)[:auth_token]

  def create_project(name) do
    if is_nil(@api_url) or is_nil(@auth_token) do
      {:error, "10000ft not configured"}
    else
      handle_request(name)
    end
  end

  defp handle_request(name) do
    {:ok, request} = Poison.encode(%{name: name})

    response =
      HTTPotion.post(
        "#{@api_url}/projects",
        headers: request_headers(@auth_token),
        body: request
      )

    case response.status_code do
      status when status in 200..299 -> :ok
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  defp request_headers(access_token) do
    [
      auth: "#{access_token}",
      "Content-Type": "application/json"
    ]
  end
end
