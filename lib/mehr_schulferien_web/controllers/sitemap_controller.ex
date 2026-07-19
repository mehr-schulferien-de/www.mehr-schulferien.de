defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  import Ecto.Query

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Calendars.VacationTypes
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Repo

  @base_url "https://www.mehr-schulferien.de"

  @vacation_overview_slugs ~w(sommerferien osterferien herbstferien weihnachtsferien
                              winterferien pfingstferien)

  @developer_paths ~w(developers developers/api developers/api/locations
                      developers/api/periods developers/api/bridge-days
                      developers/api/vacation-optimizer developers/api/exports
                      developers/api/pdf developers/api/queries
                      developers/api/reference developers/mcp)

  @doc """
  Sitemap index pointing to the per-type child sitemaps, so Search Console
  reports indexing coverage per page type. Noindexed tool pages
  (urlaubsplaner, per-school briefe) are deliberately absent everywhere.
  """
  def index(conn, _params) do
    sitemap_urls =
      for name <- ~w(static bundeslaender staedte schulen),
          do: "#{@base_url}/sitemap-#{name}.xml"

    render_xml(conn, "index.xml", sitemap_urls: sitemap_urls)
  end

  @doc "Homepage, vacation type overviews, country and info pages."
  def static(conn, _params) do
    today = DateHelpers.today_berlin()
    countries = Locations.list_countries()

    vacation_overviews =
      for slug <- @vacation_overview_slugs do
        %{loc: "#{@base_url}/#{slug}", changefreq: "weekly", priority: "0.9"}
      end

    country_pages =
      for country <- countries do
        %{loc: "#{@base_url}/ferien/#{country.slug}", changefreq: "weekly", priority: "0.8"}
      end

    bridge_day_overviews =
      for country <- countries, year <- [today.year, today.year + 1] do
        %{
          loc: "#{@base_url}/brueckentage/#{country.slug}/#{year}",
          changefreq: "weekly",
          priority: "0.8"
        }
      end

    developer_pages =
      for path <- @developer_paths do
        %{loc: "#{@base_url}/#{path}", changefreq: "monthly", priority: "0.4"}
      end

    entries =
      [%{loc: "#{@base_url}/", lastmod: today, changefreq: "daily", priority: "1.0"}] ++
        vacation_overviews ++
        country_pages ++
        bridge_day_overviews ++
        [%{loc: "#{@base_url}/briefe", changefreq: "monthly", priority: "0.6"}] ++
        developer_pages ++
        [%{loc: "#{@base_url}/impressum", changefreq: "yearly", priority: "0.3"}]

    render_xml(conn, "urlset.xml", entries: entries)
  end

  @doc "Evergreen state pages plus their year, season, bridge day and date query pages."
  def federal_states(conn, _params) do
    today = DateHelpers.today_berlin()
    years = [today.year, today.year + 1]

    entries =
      for country <- Locations.list_countries(),
          state_meta <- list_federal_states_with_metadata(country),
          entry <- state_entries(country, state_meta, years, today),
          do: entry

    render_xml(conn, "urlset.xml", entries: entries)
  end

  @doc "All city pages (year-less evergreen URLs; year URLs 301 to them)."
  def cities(conn, _params) do
    entries =
      city_country_slugs()
      |> Enum.map(fn {country_slug, city_slug} ->
        %{
          loc: "#{@base_url}/ferien/#{country_slug}/stadt/#{city_slug}",
          changefreq: "weekly",
          priority: "0.6"
        }
      end)

    render_xml(conn, "urlset.xml", entries: entries)
  end

  @doc "All school pages (year-less evergreen URLs; year URLs 301 to them)."
  def schools(conn, _params) do
    entries =
      school_country_slugs()
      |> Enum.map(fn {country_slug, school_slug} ->
        %{
          loc: "#{@base_url}/ferien/#{country_slug}/schule/#{school_slug}",
          changefreq: "weekly",
          priority: "0.6"
        }
      end)

    render_xml(conn, "urlset.xml", entries: entries)
  end

  defp render_xml(conn, template, assigns) do
    conn
    |> put_resp_content_type("text/xml")
    |> render(template, assigns)
  end

  defp list_federal_states_with_metadata(country) do
    states =
      Repo.all(
        from l in Location,
          where: l.parent_location_id == ^country.id and l.is_federal_state == true,
          order_by: l.slug
      )

    periods_by_state =
      Repo.all(
        from p in Period,
          where: p.location_id in ^Enum.map(states, & &1.id),
          select: {p.location_id, p.starts_on, p.ends_on, p.updated_at}
      )
      |> Enum.group_by(&elem(&1, 0))

    Enum.map(states, fn state ->
      periods = Map.get(periods_by_state, state.id, [])

      period_years =
        periods
        |> Enum.flat_map(fn {_id, starts_on, ends_on, _updated} ->
          starts_on.year..ends_on.year
        end)
        |> Enum.uniq()

      last_modified =
        periods
        |> Enum.map(fn {_id, _starts, _ends, updated_at} -> to_date(updated_at) end)
        |> Enum.max(Date, fn -> nil end)

      %{state: state, period_years: period_years, last_modified: last_modified}
    end)
  end

  defp state_entries(country, state_meta, years, today) do
    %{state: state, period_years: period_years, last_modified: last_modified} = state_meta
    state_url = "#{@base_url}/ferien/#{country.slug}/bundesland/#{state.slug}"

    evergreen = %{loc: state_url, lastmod: last_modified, changefreq: "weekly", priority: "0.9"}

    date_query_pages =
      [
        {"ist-heute-feiertag", "0.7"},
        {"ist-heute-schulfrei", "0.7"},
        {"ist-am-montag-schule", "0.6"},
        {"ist-am-freitag-schule", "0.6"}
      ]
      |> Enum.map(fn {prefix, priority} ->
        %{
          loc: "#{@base_url}/#{prefix}/#{state.slug}",
          lastmod: today,
          changefreq: "daily",
          priority: priority
        }
      end)

    year_pages =
      for year <- years, year in period_years do
        season_pages =
          for vacation_type <- VacationTypes.list_for_year(state, year) do
            %{
              loc: "#{@base_url}/#{vacation_type.slug}ferien/#{state.slug}/#{year}",
              lastmod: last_modified,
              changefreq: "weekly",
              priority: "0.85"
            }
          end

        [
          %{
            loc: "#{state_url}/#{year}",
            lastmod: last_modified,
            changefreq: "weekly",
            priority: "0.8"
          },
          %{
            loc: "#{@base_url}/brueckentage/#{country.slug}/bundesland/#{state.slug}/#{year}",
            changefreq: "weekly",
            priority: "0.7"
          }
          | season_pages
        ]
      end

    [evergreen | date_query_pages] ++ List.flatten(year_pages)
  end

  defp city_country_slugs do
    Repo.all(
      from city in Location,
        join: county in Location,
        on: city.parent_location_id == county.id,
        join: state in Location,
        on: county.parent_location_id == state.id,
        join: country in Location,
        on: state.parent_location_id == country.id,
        where: city.is_city == true,
        order_by: city.slug,
        select: {country.slug, city.slug}
    )
  end

  defp school_country_slugs do
    Repo.all(
      from school in Location,
        join: city in Location,
        on: school.parent_location_id == city.id,
        join: county in Location,
        on: city.parent_location_id == county.id,
        join: state in Location,
        on: county.parent_location_id == state.id,
        join: country in Location,
        on: state.parent_location_id == country.id,
        where: school.is_school == true and school.is_quarantined == false,
        order_by: school.slug,
        select: {country.slug, school.slug}
    )
  end

  defp to_date(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_date(datetime)
  defp to_date(%DateTime{} = datetime), do: DateTime.to_date(datetime)
end
