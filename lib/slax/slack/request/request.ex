defmodule Slax.Slack.Request do
  @moduledoc """
  Defines an behavior for making requests to the Slack API.
  """

  @doc """
    # Example

    iex> get("users.profile.get", %{user: 1}, "xoxb_123457890")
    {:ok, %{"ok" => true, "profile" => profile}, 200}
  """
  @callback get(
              method :: binary(),
              params :: [{String.t(), String.t()}],
              token :: binary() | nil
            ) :: {:ok, map() | list(), status_code :: integer()} | {:error, any()}
  def get(method, params, token \\ nil)

  def get(method, params, token) do
    module().get(method, params, token)
  end

  @doc """
    # Example

    iex> post("chat.postMessage", %{channel: "ABCDEFGXXXX, text: "Hello, world!"}, token)
    {:ok, %{"ok" => true}, 200}
  """
  @callback post(
              method :: binary(),
              body :: map(),
              token :: binary() | nil
            ) :: {:ok, map() | list(), status_code :: integer()} | {:error, any()}

  def post(method, body, token \\ nil)

  def post(method, body, token) do
    module().post(method, body, token)
  end

  defp module do
    :slax
    |> Application.get_env(Slax.Slack)
    |> Keyword.get(:module, Slax.Slack.Request.Production)
  end
end
