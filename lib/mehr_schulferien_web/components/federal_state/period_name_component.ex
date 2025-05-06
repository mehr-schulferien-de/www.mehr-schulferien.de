defmodule MehrSchulferienWeb.FederalState.PeriodNameComponent do
  use Phoenix.Component

  attr :period, :map, required: true

  def period_name(assigns) do
    ~H"""
    <%= cond do %>
      <% is_map_key(@period.holiday_or_vacation_type, :colloquial) && @period.holiday_or_vacation_type.colloquial && @period.holiday_or_vacation_type.colloquial != "" -> %>
        <%= @period.holiday_or_vacation_type.colloquial %>
      <% is_map_key(@period.holiday_or_vacation_type, :colloquial_name) && @period.holiday_or_vacation_type.colloquial_name && @period.holiday_or_vacation_type.colloquial_name != "" -> %>
        <%= @period.holiday_or_vacation_type.colloquial_name %>
      <% true -> %>
        <%= @period.holiday_or_vacation_type.name %>
    <% end %>
    """
  end
end
