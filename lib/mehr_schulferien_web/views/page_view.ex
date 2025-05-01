defmodule MehrSchulferienWeb.PageView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.{Locations, BridgeDays, PeriodDisplay}

  def number_schools() do
    Locations.number_schools()
  end

  def get_school_period(periods) do
    PeriodDisplay.get_school_period(periods)
  end

  def display_period_info?(date, dates, period) do
    PeriodDisplay.display_period_info?(date, dates, period)
  end

  def get_period_colspan(date, last_date, period) do
    PeriodDisplay.get_period_colspan(date, last_date, period)
  end

  def show_period_info(period, colspan) do
    PeriodDisplay.show_period_info(period, colspan)
  end

  def get_non_school_period(date, period, periods) do
    PeriodDisplay.get_non_school_period(date, period, periods)
  end

  def best_bridge_day_teaser do
    BridgeDays.best_bridge_day_teaser()
  end
end
