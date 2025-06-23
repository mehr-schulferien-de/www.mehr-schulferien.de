defmodule MehrSchulferienWeb.Shared.PageLayoutComponent do
  @moduledoc """
  Shared page layout component for two-column responsive layouts.
  Replaces the duplicated layout pattern found across federal state, city, and school templates.
  """
  use Phoenix.Component

  slot :main_content, required: true
  slot :sidebar_content, required: true
  attr :class, :string, default: ""

  def two_column_layout(assigns) do
    ~H"""
    <div class={"flex flex-col lg:flex-row gap-6 #{@class}"}>
      <div class="lg:w-2/3 bg-white p-4 rounded-lg shadow-sm">
        <%= render_slot(@main_content) %>
      </div>
      <div class="lg:w-1/3">
        <%= render_slot(@sidebar_content) %>
      </div>
    </div>
    """
  end

  slot :content, required: true
  attr :class, :string, default: ""

  def single_column_layout(assigns) do
    ~H"""
    <div class={"bg-white p-4 rounded-lg shadow-sm #{@class}"}>
      <%= render_slot(@content) %>
    </div>
    """
  end
end
