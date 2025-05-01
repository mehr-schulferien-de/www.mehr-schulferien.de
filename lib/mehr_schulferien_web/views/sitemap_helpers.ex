defmodule MehrSchulferienWeb.SitemapHelpers do
  @moduledoc """
  Helper functions for generating sitemap entries.
  """

  alias MehrSchulferien.Periods
  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Generates a sitemap URL entry with the given attributes.
  """
  def url_entry(location, changefreq, priority, lastmod \\ nil) do
    """
    <url>
      <loc>#{location}</loc>
      <changefreq>#{changefreq}</changefreq>
      #{if lastmod, do: "<lastmod>#{lastmod}</lastmod>", else: ""}
      <priority>#{priority}</priority>
    </url>
    """
  end

  @doc """
  Renders a URL entry for a federal state.
  """
  def federal_state_entry(conn, country, federal_state, today) do
    location = MehrSchulferienWeb.Router.Helpers.federal_state_url(conn, :show, country.slug, federal_state.slug)
    url_entry(location, "daily", "0.6", today)
  end

  @doc """
  Renders a URL entry for a bridge day within a federal state.
  """
  def bridge_day_entry(conn, country, federal_state) do
    location = MehrSchulferienWeb.Router.Helpers.bridge_day_url(conn, :index_within_federal_state, country.slug, federal_state.slug)
    url_entry(location, "monthly", "0.5")
  end

  @doc """
  Renders a URL entry for a bridge day within a federal state for a specific year.
  """
  def yearly_bridge_day_entry(conn, country, federal_state, year) do
    location = MehrSchulferienWeb.Router.Helpers.bridge_day_url(conn, :show_within_federal_state, country.slug, federal_state.slug, year)
    url_entry(location, "monthly", "0.5")
  end

  @doc """
  Checks if a location has bridge days for a given year.
  Returns true if there are any bridge days, false otherwise.
  """
  def has_bridge_days?(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    Enum.any?(2..5, fn num ->
      if bridge_day_map[num], do: Enum.count(bridge_day_map[num]) > 0, else: false
    end)
  end

  @doc """
  Returns a list of years that have bridge days for the given locations.
  Checks the current year and next two years.
  """
  def years_with_bridge_days(location_ids) do
    today = DateHelpers.today_berlin()
    
    today.year..(today.year + 2)
    |> Enum.filter(fn year -> has_bridge_days?(location_ids, year) end)
  end

  @doc """
  Renders a URL entry for a holiday or vacation type within a federal state.
  """
  def holiday_type_entry(conn, country, federal_state, vacation_type) do
    location = MehrSchulferienWeb.Router.Helpers.federal_state_url(conn, :show_holiday_or_vacation_type, country.slug, federal_state.slug, vacation_type.slug)
    url_entry(location, "monthly", "0.4")
  end

  @doc """
  Renders a URL entry for a city.
  """
  def city_entry(conn, country, city, most_recent_period) do
    location = MehrSchulferienWeb.Router.Helpers.city_url(conn, :show, country.slug, city.slug)
    lastmod = 
      if most_recent_period do
        Date.add(most_recent_period.ends_on, 1)
      else
        nil
      end
    url_entry(location, "monthly", "0.5", lastmod)
  end

  @doc """
  Renders a URL entry for a school.
  """
  def school_entry(conn, country, school, most_recent_period) do
    location = MehrSchulferienWeb.Router.Helpers.school_url(conn, :show, country.slug, school.slug)
    lastmod = 
      if most_recent_period do
        Date.add(most_recent_period.ends_on, 1)
      else
        nil
      end
    url_entry(location, "monthly", "0.5", lastmod)
  end
end 