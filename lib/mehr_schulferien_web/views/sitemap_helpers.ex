defmodule MehrSchulferienWeb.SitemapHelpers do
  @moduledoc """
  Helper functions for generating sitemap entries.
  """

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