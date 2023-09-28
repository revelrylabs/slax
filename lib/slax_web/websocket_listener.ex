defmodule SlaxWeb.WebsocketListener do
  use GenServer
  require Logger

  alias Slax.Http
  alias SlaxWeb.Issue
  alias SlaxWeb.Poker
  alias SlaxWeb.Token

  defp config() do
    Application.get_env(:slax, Slax.Slack)
  end

  defp app_token() do
    config()[:app_token]
  end

  def init(_) do
    {:ok, %{body: %{"url" => "wss://wss-primary.slack.com" <> path}}} =
      Http.post(
        "https://slack.com/api/apps.connections.open",
        "",
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Bearer #{app_token()}"
      )

    {:ok, pid} =
      :gun.open(:binary.bin_to_list("wss-primary.slack.com"), 443, %{
        connect_timeout: 60000,
        retry: 10,
        retry_timeout: 300,
        transport: :tls,
        protocols: [:http],
        http_opts: %{version: :"HTTP/1.1"},
        tls_opts: [
          verify: :verify_none,
          cacerts: :certifi.cacerts(),
          depth: 99,
          reuse_sessions: false
        ]
      })

    {:ok, :http} = :gun.await_up(pid, 10_000)
    stream = :gun.ws_upgrade(pid, path)
    {:upgrade, [<<"websocket">>], _headers} = :gun.await(pid, stream, 10_000)

    {:ok, nil}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def handle_info({_, pid, stream_ref, {:text, event}}, socket) do
    with {:ok, decoded_event} <- Jason.decode(event) do
      handle_message(pid, stream_ref, decoded_event)
    else
      _ ->
        nil
    end

    {:noreply, socket}
  end

  # Handle disconnects
  defp handle_message(pid, _, %{"type" => "disconnect"}) do
    :gun.close(pid)
    init(nil)
  end

  # Websocket init message
  defp handle_message(_, _, %{"type" => "hello"}), do: nil

  defp handle_message(pid, stream_ref, %{
         "type" => "events_api",
         "envelope_id" => envelope_id,
         "payload" => %{"event" => event}
       }) do
    Issue.handle_event(event)

    with {:ok, response} <- Jason.encode(%{envelope_id: envelope_id}) do
      :gun.ws_send(pid, stream_ref, {:text, response})
    else
      _ ->
        nil
    end
  end

  defp handle_message(pid, stream_ref, %{
         "type" => "slash_commands",
         "envelope_id" => envelope_id,
         "payload" => payload
       }) do
    with {:ok, response} <-
           Jason.encode(%{envelope_id: envelope_id, payload: Poker.start(payload)}) do
      :gun.ws_send(pid, stream_ref, {:text, response})
    else
      _ ->
        nil
    end
  end

  defp handle_message(pid, stream_ref, %{
         "type" => "interactive",
         "envelope_id" => envelope_id,
         "payload" => payload
       }) do
    with %{} = view <- Token.handle_payload(payload),
         {:ok, response} <-
           Jason.encode(%{
             envelope_id: envelope_id,
             payload: %{response_action: "update", view: view}
           }) do
      :gun.ws_send(pid, stream_ref, {:text, response})
    else
      :ok ->
        response = Jason.encode!(%{envelope_id: envelope_id})
        :gun.ws_send(pid, stream_ref, {:text, response})

      _ ->
        nil
    end
  end
end
