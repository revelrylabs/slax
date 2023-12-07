defmodule Slax.Channels.Channels do
  use Slax.Context

  alias Slax.Channels.Channel

  def create_or_update_channel(channel_id, %{name: name} = attrs) do
    case Repo.get_by(Channel, %{channel_id: channel_id, name: name}) do
      nil -> %Channel{channel_id: channel_id, name: name}
      channel -> channel
    end
    |> Channel.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def get_all() do
    Repo.all(Channel)
  end

  def get_by_channel_id(channel_id) do
    Repo.get_by(Channel, channel_id: channel_id)
  end

  def disabled?(channel_id) do
    Map.get(get_by_channel_id(channel_id), :disabled)
  end
end