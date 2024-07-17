defmodule Slax.Http do
  @moduledoc false
  def post(url, body, headers \\ [], options \\ []) do
    url
    |> http_adapter().post(body, headers, options)
    |> process_response_body(url)
  end

  def put(url, body, headers \\ [], options \\ []) do
    url
    |> http_adapter().put(body, headers, options)
    |> process_response_body(url)
  end

  def patch(url, body, headers \\ [], options \\ []) do
    url
    |> http_adapter().patch(body, headers, options)
    |> process_response_body(url)
  end

  def get(url, headers \\ [], options \\ []) do
    url
    |> http_adapter().get(headers, options)
    |> process_response_body(url)
  end

  defp http_adapter, do: Application.get_env(:slax, :http_adapter)

  defp process_response_body(
         {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}},
         url
       )
       when status_code in 200..299 do
    {
      :ok,
      %{
        headers: headers,
        status_code: status_code,
        body: parse_body(body),
        url: url
      }
    }
  end

  defp process_response_body(
         {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}},
         url
       ) do
    {
      :error,
      %{
        headers: headers,
        status_code: status_code,
        body: parse_body(body),
        url: url
      }
    }
  end

  defp process_response_body({:error, %HTTPoison.Error{reason: {_, reason}}}, _url),
    do: {:error, reason}

  defp process_response_body({:error, %HTTPoison.Error{reason: reason}}, _url),
    do: {:error, reason}

  defp process_response_body({:error, reason}, _url),
    do: {:error, reason}

  defp parse_body(body) do
    case Jason.decode(body) do
      {:ok, decoded_body} -> decoded_body
      _ -> body
    end
  end
end
