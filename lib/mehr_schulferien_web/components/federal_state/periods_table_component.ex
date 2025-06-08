defmodule MehrSchulferienWeb.FederalState.PeriodsTableComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.Shared.PeriodsTableComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()

  def periods_table(assigns) do
    ~H"""
    <.render_periods_table
      periods={@periods}
      all_periods={@all_periods}
      today={@today}
      group_by_school_year={false}
      anchor_link_format="month_name_year"
    />
    """
  end
end
