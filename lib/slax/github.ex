defmodule Slax.Github do
  @moduledoc """
  Functions for working with the Github API
  """

  alias Slax.{Http, ProjectRepos}
  alias Slax.Http.Error

  defp config() do
    Application.get_env(:slax, __MODULE__)
  end

  defp api_url() do
    config()[:api_url]
  end

  defp oauth_url() do
    config()[:oauth_url]
  end

  defp default_org() do
    config()[:org_name]
  end

  @doc """
  Public function to allow other modules to use the default Github api key
  """
  def api_token() do
    config()[:api_token]
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
      Http.post(
        "#{oauth_url()}/access_token",
        request_body,
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
      )

    case response do
      {:ok, %{body: body}} ->
        Map.get(body, "access_token")

      {:error, error} ->
        raise Error,
          message: "error response, got: #{inspect(error)}"
    end
  end

  @doc """
  Create an issue
  """
  def create_issue(params) do
    {:ok, request} =
      Jason.encode(%{
        title: params[:title],
        body: params[:body],
        labels: Map.get(params, :labels, []),
        assignees: Map.get(params, :assignees, [])
      })

    response =
      Http.post(
        "#{api_url()}/repos/#{params[:repo]}/issues",
        request,
        request_headers(params[:access_token])
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, Map.get(body, "html_url")}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Create a comment on an issue
  """
  def create_comment(params) do
    {:ok, request} =
      Jason.encode(%{
        body: params[:body]
      })

    response =
      Http.post(
        "#{api_url()}/repos/#{params[:org]}/#{params[:repo]}/issues/#{params[:issue_number]}/comments",
        request,
        request_headers(params[:access_token])
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, Map.get(body, "html_url")}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Fetch information about the currently authenticated user
  """
  def current_user_info(params) do
    response = Http.get("#{api_url()}/user", request_headers(params[:access_token]))

    case response do
      {:ok, %{body: body}} ->
        body

      {:error, error} ->
        raise Error,
          message: "error response, got: #{inspect(error)}"
    end
  end

  @doc """
  Fetch issues from a repo created by a specific user
  """
  def fetch_issues(params) do
    "#{api_url()}/repos/#{params[:org]}/#{params[:repo]}/issues"
    |> fetch_issues_from_url(params)
  end

  defp fetch_issues_from_url(url, params) do
    access_token = request_headers(params[:access_token])
    response = Http.get(url, access_token)

    case response do
      {:ok, %{body: body}} ->
        body
        |> Enum.map(fn issue ->
          Map.merge(issue, %{"org" => params[:org], "repo" => params[:repo]})
        end)

      {:error, %{status_code: 301, body: _body, headers: headers}} ->
        location =
          headers
          |> Enum.find_value(fn {header, value} ->
            case header do
              "Location" ->
                value

              _ ->
                false
            end
          end)

        fetch_issues_from_url(location, params)

      {:error, %{body: body}} ->
        body
    end
  end

  @doc """
  Fetch a single issue
  """
  def fetch_issue(params) do
    response =
      Http.get(
        "#{api_url()}/repos/#{params[:repo]}/issues/#{params[:number]}",
        request_headers(params[:access_token])
      )

    case response do
      {:ok, %{body: body}} ->
        body

      {:error, %{body: body}} ->
        body
    end
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

    response =
      Http.get(
        "#{api_url()}/repos/#{params[:repo]}/milestones?#{query_string}",
        request_headers(params[:access_token])
      )

    case response do
      {_, %{status_code: 404}} -> {:error, :not_found}
      {:ok, %{body: body}} -> {:ok, body}
    end
  end

  @doc """
  Create a milestone for a repo
  """
  def create_milestone(params) do
    {:ok, request} =
      Jason.encode(%{
        title: params[:title],
        description: params[:description]
      })

    response =
      Http.post(
        "#{api_url()}/repos/#{params[:repo]}/milestones",
        request,
        request_headers(params[:access_token])
      )

    case response do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, %{body: body}} -> {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Add a single issue to a milestone
  """
  def add_issue_to_milestone(params) do
    {:ok, request} =
      Jason.encode(%{
        milestone: params[:milestone_number]
      })

    response =
      Http.patch(
        "#{api_url()}/repos/#{params[:repo]}/issues/#{params[:issue_number]}",
        request,
        request_headers(params[:access_token])
      )

    case response do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, %{body: body}} -> {:error, Map.get(body, "message")}
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
      Jason.encode(%{
        name: params[:name],
        private: true
      })

    response =
      Http.post(
        "#{api_url()}/orgs/#{org_name}/repos",
        request,
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, Map.get(body, "html_url")}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Gets info for a repo from github
  """
  def fetch_repo(params) do
    org_name = params[:org_name]
    name = params[:name]

    response =
      Http.get(
        "#{api_url()}/repos/#{org_name}/#{name}",
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {_, %{status_code: 404}} ->
        :not_found

      {:ok, %{body: body}} ->
        {:ok, Map.get(body, "html_url")}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Creates a webhook
  """
  def create_webhook(params) do
    repo = params[:repo]

    {:ok, request} =
      Jason.encode(%{
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
      Http.post(
        "#{api_url()}/repos/#{repo}/hooks",
        request,
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, Map.get(body, "id")}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Gets the tree for the given repo
  """
  def fetch_tree(params) do
    repo = params[:repo]

    response =
      Http.get(
        "#{api_url()}/repos/#{repo}/git/trees/master?recursive=1",
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  @doc """
  Gets the specified blob
  """
  def fetch_blob(params) do
    repo = params[:repo]
    sha = params[:sha]

    response =
      Http.get(
        "#{api_url()}/repos/#{repo}/git/blobs/#{sha}",
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  def list_teams(params) do
    org = params[:org]

    response =
      Http.get(
        "#{api_url()}/orgs/#{org}/teams",
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  def add_team_to_repo(params) do
    repo = params[:repo]
    team = params[:team]

    {:ok, request} =
      Jason.encode(%{
        permission: "push"
      })

    response =
      Http.put(
        "#{api_url()}/teams/#{team}/repos/#{repo}",
        request,
        request_headers(params[:access_token]),
        timeout: @timeout_length
      )

    case response do
      {:ok, _response} ->
        {:ok, "Created"}

      {:error, %{body: body}} ->
        {:error, Map.get(body, "message")}
    end
  end

  defp request_headers(access_token) do
    [
      Authorization: "token #{access_token}",
      "Content-Type": "application/json",
      "User-Agent": "Content Bot 1.0"
    ]
  end

  @doc """
  Extract the the organization, repository and issue number from a string

  ## Examples

      iex> parse_repo_org_issue("revelrylabs/slax/1")
      {"revelrylabs", "slax", "1"}
      iex> parse_repo_org_issue("slax/1")
      {"revelrylabs", "slax", "1"}
      iex> parse_repo_org_issue("")
      {:error, "Could not parse repo and issue, use repo/issue or org/repo/issue"}

  """
  def parse_repo_org_issue(string) do
    string
    |> String.split(["/", "#"])
    |> case do
      [org, repo, issue] -> {org, repo, issue}
      [repo, issue] -> {default_org(), repo, issue}
      _ -> {:error, "Could not parse repo and issue, use repo/issue or org/repo/issue"}
    end
  end

  @doc """
  Loads specified issue returning informational errors
  """
  def load_issue(repo_and_issue) do
    with {org, repo, issue} <- parse_repo_org_issue(repo_and_issue),
         %{token: token} when not is_nil(token) <- ProjectRepos.get_by_repo(repo),
         client <- Tentacat.Client.new(%{access_token: token}),
         {200, issue, _http_response} <- Tentacat.Issues.find(client, org, repo, issue) do
      {:ok, issue}
    else
      {:error, _message} = error ->
        error

      {_response_code, %{"message" => "Bad credentials"}, _http_response} ->
        {:error, "Access token invalid"}

      {_response_code, %{"message" => error_message}, _http_response} ->
        {:error, error_message}

      nil ->
        {:error, "No project repo set"}

      %{token: nil} ->
        {:error, "No access token"}
    end
  end
end
