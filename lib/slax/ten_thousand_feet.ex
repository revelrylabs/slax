defmodule Slax.TenThousandFeet do
  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp api_url() do
    config()[:api_endpoint]
  end

  defp auth_token() do
    config()[:auth_token]
  end

  def create_project(name) do
    if is_nil(api_url()) or is_nil(auth_token()) do
      {:error, "10000ft not configured"}
    else
      handle_request(name)
    end
  end

  defp handle_request(name) do
    {:ok, request} = Poison.encode(%{name: name})

    response =
      HTTPotion.post(
        "#{api_url()}/projects",
        headers: request_headers(auth_token()),
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
