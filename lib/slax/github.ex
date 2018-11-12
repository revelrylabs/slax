defmodule Slax.Github do
  @moduledoc """
  Functions for working with the Github API
  """

  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp api_url() do
    config()[:api_url]
  end

  defp oauth_url() do
    config()[:oauth_url]
  end

  @timeout_length 10_000

  @doc """
  URL to send a user to authorize your application.

  More documentation: https://developer.github.com/v3/oauth/
  """
  def authorize_url(params) do
    query_string = URI.encode_query(params)

    "#{oauth_url()}/authorize?#{query_string}"
  end

  @doc """
  Uses the code sent back from Github to request an access token
  """
  def fetch_access_token(params) do
    request_body = URI.encode_query(params)

    response =
      HTTPotion.post(
        "#{oauth_url()}/access_token",
        body: request_body,
        headers: [Accept: "application/json"]
      )

    Poison.decode!(response.body) |> Map.get("access_token")
  end

  @doc """
  Create an issue
  """
  def create_issue(params) do
    {:ok, request} =
      Poison.encode(%{
        title: params[:title],
        body: params[:body],
        labels: Map.get(params, :labels, []),
        assignees: Map.get(params, :assignees, [])
      })

    response =
      HTTPotion.post(
        "#{api_url()}/repos/#{params[:repo]}/issues",
        headers: request_headers(params[:access_token]),
        body: request
      )

    case response.status_code do
      201 -> {:ok, Poison.decode!(response.body) |> Map.get("html_url")}
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  @doc """
  Create a comment on an issue
  """
  def create_comment(params) do
    {:ok, request} =
      Poison.encode(%{
        body: params[:body]
      })

    response =
      HTTPotion.post(
        "#{api_url()}/repos/#{params[:org]}/#{params[:repo]}/issues/#{params[:issue_number]}/comments",
        headers: request_headers(params[:access_token]),
        body: request
      )

    case response.status_code do
      201 -> {:ok, Poison.decode!(response.body) |> Map.get("html_url")}
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  @doc """
  Fetch information about the currently authenticated user
  """
  def current_user_info(params) do
    response = HTTPotion.get("#{api_url()}/user", headers: request_headers(params[:access_token]))

    Poison.decode!(response.body)
  end

  @doc """
  Fetch issues from a repo created by a specific user
  """
  def fetch_issues(params) do
    query_string =
      URI.encode_query(%{
        creator: params[:username]
      })

    response =
      HTTPotion.get(
        "#{api_url()}/repos/#{params[:repo]}/issues?#{query_string}",
        headers: request_headers(params[:access_token])
      )

    response.body
    |> Poison.decode!()
  end

  @doc """
  Fetch a single issue
  """
  def fetch_issue(params) do
    response =
      HTTPotion.get(
        "#{api_url()}/repos/#{params[:repo]}/issues/#{params[:number]}",
        headers: request_headers(params[:access_token])
      )

    Poison.decode!(response.body)
  end

  @doc """
  Fetch all milestones for a repo
  """
  def fetch_milestones(params) do
    query_string =
      URI.encode_query(%{
        state: Map.get(params, :state, "open"),
        sort: Map.get(params, :sort, "due_on"),
        direction: Map.get(params, :direction, "asc")
      })

    HTTPotion.get(
      "#{api_url()}/repos/#{params[:repo]}/milestones?#{query_string}",
      headers: request_headers(params[:access_token])
    )
    |> case do
      %{status_code: 404} -> {:error, :not_found}
      %{body: body} -> {:ok, Poison.decode!(body)}
    end
  end

  @doc """
  Create a milestone for a repo
  """
  def create_milestone(params) do
    {:ok, request} =
      Poison.encode(%{
        title: params[:title],
        description: params[:description]
      })

    response =
      HTTPotion.post(
        "#{api_url()}/repos/#{params[:repo]}/milestones",
        headers: request_headers(params[:access_token]),
        body: request
      )

    case response.status_code do
      201 -> {:ok, Poison.decode!(response.body)}
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  @doc """
  Add a single issue to a milestone
  """
  def add_issue_to_milestone(params) do
    {:ok, request} =
      Poison.encode(%{
        milestone: params[:milestone_number]
      })

    response =
      HTTPotion.patch(
        "#{api_url()}/repos/#{params[:repo]}/issues/#{params[:issue_number]}",
        headers: request_headers(params[:access_token]),
        body: request
      )

    case response.status_code do
      200 -> {:ok, Poison.decode!(response.body)}
      _ -> {:error, Poison.decode!(response.body) |> Map.get("message")}
    end
  end

  @doc """
  Tries to find the repo given. If not found then
  it creates it
  """
  def find_or_create_repo(params) do
    case fetch_repo(params) do
      {:ok, _} = success ->
        success

      :not_found ->
        create_repo(params)

      error ->
        error
    end
  end

  @doc """
  Creates a repo
  """
  def create_repo(params) do
    org_name = params[:org_name]

    {:ok, request} =
      Poison.encode(%{
        name: params[:name],
        private: true
      })

    response =
      HTTPotion.post(
        "#{api_url()}/orgs/#{org_name}/repos",
        headers: request_headers(params[:access_token]),
        body: request,
        timeout: @timeout_length
      )

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
  Gets info for a repo from github
  """
  def fetch_repo(params) do
    org_name = params[:org_name]
    name = params[:name]

    response =
      HTTPotion.get(
        "#{api_url()}/repos/#{org_name}/#{name}",
        headers: request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response.status_code do
      201 ->
        body = Poison.decode!(response.body)
        {:ok, body |> Map.get("html_url")}

      404 ->
        :not_found

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

    {:ok, request} =
      Poison.encode(%{
        name: params[:name],
        active: true,
        events: params[:events],
        config: %{
          url: params[:url],
          content_type: "json",
          secret: params[:secret]
        }
      })

    response =
      HTTPotion.post(
        "#{api_url()}/repos/#{repo}/hooks",
        headers: request_headers(params[:access_token]),
        body: request,
        timeout: @timeout_length
      )

    case response.status_code do
      201 ->
        body = Poison.decode!(response.body)
        {:ok, body |> Map.get("id")}

      _ ->
        body = Poison.decode!(response.body)
        {:error, body |> Map.get("message")}
    end
  end

  @doc """
  Gets the tree for the given repo
  """
  def fetch_tree(params) do
    repo = params[:repo]

    response =
      HTTPotion.get(
        "#{api_url()}/repos/#{repo}/git/trees/master?recursive=1",
        headers: request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case handle_response(response) do
      {:ok, _} = ok ->
        ok

      {:error, data} ->
        {:error, data["message"]}
    end
  end

  @doc """
  Gets the specified blob
  """
  def fetch_blob(params) do
    repo = params[:repo]
    sha = params[:sha]

    response =
      HTTPotion.get(
        "#{api_url()}/repos/#{repo}/git/blobs/#{sha}",
        headers: request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case handle_response(response) do
      {:ok, _} = ok ->
        ok

      {:error, data} ->
        {:error, data["message"]}
    end
  end

  def list_teams(params) do
    org = params[:org]

    response =
      HTTPotion.get(
        "#{api_url()}/orgs/#{org}/teams",
        headers: request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case handle_response(response) do
      {:ok, _} = ok ->
        ok

      {:error, data} ->
        {:error, data["message"]}
    end
  end

  def add_team_to_repo(params) do
    repo = params[:repo]
    team = params[:team]

    {:ok, request} =
      Poison.encode(%{
        permission: "push"
      })

    response =
      HTTPotion.put(
        "#{api_url()}/teams/#{team}/repos/#{repo}",
        headers: request_headers(params[:access_token]),
        body: request,
        timeout: @timeout_length
      )

    case response.status_code do
      ok when ok in 200..299 ->
        {:ok, "Created"}

      _ ->
        body = Poison.decode!(response.body)
        {:error, body["message"]}
    end
  end

  defp handle_response(response) do
    body = Poison.decode!(response.body)

    case response.status_code do
      ok when ok in 200..299 ->
        {:ok, body}

      _ ->
        {:error, body}
    end
  end

  defp request_headers(access_token) do
    [
      Authorization: "token #{access_token}",
      "Content-Type": "application/json",
      "User-Agent": "Content Bot 1.0"
    ]
  end
end
