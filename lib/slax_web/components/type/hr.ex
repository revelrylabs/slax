defmodule SlaxWeb.Components.Type.HR do
  @moduledoc false
  use SlaxWeb, :component

  def render(assigns) do
    ~F"""
    <hr class="my-5">
    """
  end
end
