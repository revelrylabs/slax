defmodule SlaxWeb.LiveViews.Account.Shoutout do
  @moduledoc false
  use SlaxWeb, :component

  prop shoutout, :struct

  def render(assigns) do
    ~F"""
    <div class="bg-white flex flex-row overflow-hidden">
      <img src={@shoutout.sender.avatar} class="w-10 h-10 rounded-full">
      <div class="pl-5 w-full">
        <div class="text-sm text-gray-500 mt-2"><span class="font-bold">{receiver_names(@shoutout.receivers)}</span> {@shoutout.message}</div>
        <div class="flex flex-row justify-between">
          <div class="text-xs text-gray-400 mt-3">{@shoutout.sender.name}</div>
          <div class="text-xs text-gray-400 mt-3">{Timex.format!(@shoutout.inserted_at, "{relative}", :relative)}</div>
        </div>
      </div>
    </div>
    """
  end

  defp receiver_names([receiver]) do
    receiver.name
  end

  defp receiver_names([receiver1, receiver2]) do
    "#{receiver1.name} and #{receiver2.name}"
  end

  defp receiver_names([receiver | receivers]) do
    comma_separated =
      receivers
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    "#{comma_separated} and #{receiver.name}"
  end
end
