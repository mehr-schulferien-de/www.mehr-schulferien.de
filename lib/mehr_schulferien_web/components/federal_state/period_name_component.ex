defmodule MehrSchulferienWeb.FederalState.PeriodNameComponent do
  use Phoenix.Component

  attr :period, :map, required: true

  def period_name(assigns) do
    # Check if vacation spans across years
    spans_years = assigns.period.starts_on.year != assigns.period.ends_on.year

    assigns = assign(assigns, :spans_years, spans_years)

    ~H"""
    <%= cond do %>
      <% is_map_key(@period.holiday_or_vacation_type, :colloquial) && @period.holiday_or_vacation_type.colloquial && @period.holiday_or_vacation_type.colloquial != "" -> %>
        {@period.holiday_or_vacation_type.colloquial}{if @spans_years,
          do: " #{@period.starts_on.year}"}
      <% is_map_key(@period.holiday_or_vacation_type, :colloquial_name) && @period.holiday_or_vacation_type.colloquial_name && @period.holiday_or_vacation_type.colloquial_name != "" -> %>
        {@period.holiday_or_vacation_type.colloquial_name}{if @spans_years,
          do: " #{@period.starts_on.year}"}
      <% true -> %>
        {@period.holiday_or_vacation_type.name}{if @spans_years, do: " #{@period.starts_on.year}"}
    <% end %>
    """
  end
end
