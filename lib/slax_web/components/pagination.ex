defmodule SlaxWeb.Components.Pagination do
  @moduledoc false
  use SlaxWeb, :component

  alias SlaxWeb.Components.Button

  prop page_number, :integer, required: true
  prop page_size, :integer, required: true
  prop total_entries, :integer, required: true
  prop next, :event, required: true
  prop previous, :event, required: true

  def render(assigns) do
    ~F"""
    <div
      :if={show_pagination(@total_entries, @page_size)}
      class="border-t flex flex-row justify-between pt-4"
    >
      <div class="text-sm mt-2">
        Showing {showing_start(@page_size, @page_number)}
        to {showing_end(@page_size, @page_number)} of {@total_entries} results
      </div>
      <div>
        <Button disable_with="Loading..." :if={show_previous(@page_number)} click={@previous}>Previous</Button>
        <Button
          disable_with="Loading..."
          :if={show_next(@total_entries, @page_number, @page_size)}
          click={@next}
        >Next</Button>
      </div>
    </div>
    """
  end

  defp showing_start(page_size, page_number) do
    Integer.to_string(page_size * (page_number - 1) + 1)
  end

  defp showing_end(page_size, page_number) do
    Integer.to_string(page_size * page_number)
  end

  defp show_pagination(total_entries, page_size) do
    total_entries > page_size
  end

  defp show_next(total_entries, page_number, page_size) do
    total_entries > page_number * page_size
  end

  defp show_previous(page_number) do
    page_number > 1
  end
end
