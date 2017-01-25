defmodule Github do
  @moduledoc """
  Functions for working with the Github API
  """

  @api_url "https://api.github.com"
  @oauth_url "https://github.com/login/oauth"
  @org_name Application.get_env(:slax, :github)[:org_name]

  @doc """
  URL to send a user to authorize your application.

  More documentation: https://developer.github.com/v3/oauth/
  """
  def authorize_url(params) do
    query_string = URI.encode_query(params)

    "#{@oauth_url}/authorize?#{query_string}"
  end

  @doc """
  Uses the code sent back from Github to request an access token
  """
  def fetch_access_token(params) do
    request_body = URI.encode_query(params)

    response = HTTPotion.post "#{@oauth_url}/access_token", [
      body: request_body,
      headers: ["Accept": "application/json"]
    ]

    Poison.decode!(response.body) |> Map.get("access_token")
  end

  @doc """
  Create an issue
  """
  def create_issue(params) do
    {:ok, request} = Poison.encode(%{
      title: params[:title],
      body: params[:body]
    })

    response = HTTPotion.post "#{@api_url}/repos/#{params[:repo]}/issues", [
      headers: request_headers(params[:access_token]),
      body: request
    ]

    case response.status_code do
      201 -> {:ok, Poison.decode!(response.body) |> Map.get("html_url")}
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  @doc """
  Fetch information about the currently authenticated user
  """
  def current_user_info(params) do
    response = HTTPotion.get("#{@api_url}/user", [
      headers: request_headers(params[:access_token])
    ])

    Poison.decode!(response.body)
  end

  @doc """
  Fetch issues from a repo created by a specific user
  """
  def fetch_issues(params) do
    query_string = URI.encode_query(%{
      creator: params[:username]
    })

    response = HTTPotion.get("#{@api_url}/repos/#{params[:repo]}/issues?#{query_string}", [
      headers: request_headers(params[:access_token])
    ])

    Poison.decode!(response.body)
  end


  @doc """
  Creates a repo
  """
  def create_repo(params) do

    {:ok, request} = Poison.encode(%{
          name: params[:name],
          private: true
                                   })

    response = HTTPotion.post "#{@api_url}/orgs/#{@org_name}/repos", [
      headers: request_headers(params[:access_token]),
      body: request
    ]

    case response.status_code do
      201 ->
        body = Poison.decode!(response.body)
        {:ok, body |> Map.get("html_url")}
      _ ->
        body = Poison.decode!(response.body)
        {:error, body |> Map.get("message")}
    end
  end

  @doc """
  Creates a webhook
  """
  def create_webhook(params) do
    repo = params[:repo]

    {:ok, request} = Poison.encode(%{
          name: params[:name],
          active: true,
          events: params[:events],
          config: %{
            url: params[:url],
            content_type: "json",
            secret: params[:secret]
          }
                                   })

    response = HTTPotion.post "#{@api_url}/repos/#{@org_name}/#{repo}/hooks", [
      headers: request_headers(params[:access_token]),
      body: request
    ]

    case response.status_code do
      201 ->
        body = Poison.decode!(response.body)
        {:ok, body |> Map.get("id")}
      _ ->
        body = Poison.decode!(response.body)
        {:error, body |> Map.get("message")}
    end
  end


  defp request_headers(access_token) do
    [
      "Authorization": "token #{access_token}",
      "Content-Type": "application/json",
      "User-Agent": "Content Bot 1.0"
    ]
  end
end
