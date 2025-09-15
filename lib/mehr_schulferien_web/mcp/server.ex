defmodule MehrSchulferienWeb.MCP.Server do
  @moduledoc """
  MCP (Model Context Protocol) Server for MehrSchulferien.

  Provides AI assistants with access to German school vacation and holiday data
  through a standardized protocol. All access is slug-based (no internal IDs exposed).
  """

  use Hermes.Server,
    name: "MehrSchulferien Data",
    version: "1.0.0",
    capabilities: [:tools]

  import Ecto.Query, warn: false
  alias MehrSchulferien.{Locations, Periods, BridgeDays, Repo}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Periods.Grouping
  alias MehrSchulferien.BridgeDayCalculations
  alias MehrSchulferien.Calendars.DateHelpers

  def init(_, frame) do
    {:ok,
     frame
     |> register_location_tools()
     |> register_school_tools()
     |> register_period_tools()
     |> register_bridge_day_tools()
     |> register_statistical_tools()
     |> register_export_tools()
     |> register_search_tools()}
  end

  # Location Navigation Tools
  defp register_location_tools(frame) do
    frame
    |> register_tool("get_countries",
      description: "List all available countries",
      input_schema: %{},
      annotations: %{read_only: true}
    )
    |> register_tool("get_federal_states",
      description: "List all federal states of a country",
      input_schema: %{
        country_slug: {:required, :string, description: "Country slug (e.g., 'deutschland')"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_counties",
      description: "List all counties of a federal state",
      input_schema: %{
        country_slug: {:required, :string, description: "Country slug"},
        federal_state_slug: {:required, :string, description: "Federal state slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_cities_by_state",
      description: "List all cities of a federal state",
      input_schema: %{
        country_slug: {:required, :string, description: "Country slug"},
        federal_state_slug: {:required, :string, description: "Federal state slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_cities_by_country",
      description: "List all cities of a country",
      input_schema: %{
        country_slug: {:required, :string, description: "Country slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_schools_by_city",
      description: "List all schools of a city",
      input_schema: %{
        city_slug: {:required, :string, description: "City slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_schools_by_federal_state",
      description: "List all schools in a federal state",
      input_schema: %{
        country_slug: {:required, :string, description: "Country slug"},
        federal_state_slug: {:required, :string, description: "Federal state slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_location_hierarchy",
      description: "Get full location hierarchy from any location slug",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type:
          {:required, :string,
           enum: ["country", "federal_state", "county", "city", "school"],
           description: "Type of location"}
      },
      annotations: %{read_only: true}
    )
  end

  # School Information Tools
  defp register_school_tools(frame) do
    frame
    |> register_tool("get_school_details",
      description: "Get complete school information including address and contact details",
      input_schema: %{
        school_slug: {:required, :string, description: "School slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("search_schools",
      description: "Search schools by name or keyword",
      input_schema: %{
        query: {:required, :string, description: "Search query"},
        federal_state_slug: {:optional, :string, description: "Limit to federal state"},
        city_slug: {:optional, :string, description: "Limit to city"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_nearby_schools",
      description: "Find schools within a certain distance",
      input_schema: %{
        school_slug: {:required, :string, description: "Reference school slug"},
        distance_meters:
          {:required, :integer,
           min: 100, max: 50000, description: "Distance in meters (100-50000)"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_schools_by_zip",
      description: "Find schools by zip code prefix",
      input_schema: %{
        zip_prefix:
          {:required, :string,
           pattern: "^[0-9]{3,5}$", description: "Zip code prefix (3-5 digits)"}
      },
      annotations: %{read_only: true}
    )
  end

  # Period Query Tools
  defp register_period_tools(frame) do
    frame
    |> register_tool("get_vacations",
      description: "Get school vacation periods for a location",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]},
        start_date:
          {:optional, :string,
           pattern: "^\\d{4}-\\d{2}-\\d{2}$", description: "Start date (YYYY-MM-DD)"},
        end_date:
          {:optional, :string,
           pattern: "^\\d{4}-\\d{2}-\\d{2}$", description: "End date (YYYY-MM-DD)"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_public_holidays",
      description: "Get public holidays for a location",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city"]},
        year: {:required, :integer, min: 2020, max: 2030, description: "Year (2020-2030)"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_all_periods",
      description: "Get all vacation and holiday periods combined",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]},
        year: {:required, :integer, min: 2020, max: 2030}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_next_periods",
      description: "Get upcoming vacation and holiday periods",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]},
        count:
          {:optional, :integer,
           min: 1, max: 20, default: 5, description: "Number of periods to return"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_current_periods",
      description: "Get currently active periods",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]},
        date:
          {:optional, :string,
           pattern: "^\\d{4}-\\d{2}-\\d{2}$", description: "Reference date (defaults to today)"}
      },
      annotations: %{read_only: true}
    )
  end

  # Bridge Day & Planning Tools
  defp register_bridge_day_tools(frame) do
    frame
    |> register_tool("get_bridge_days",
      description: "Calculate optimal bridge days for vacation planning",
      input_schema: %{
        federal_state_slug: {:required, :string, description: "Federal state slug"},
        year: {:required, :integer, min: 2024, max: 2030}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("check_bridge_days_availability",
      description: "Check if a location has bridge days for given years",
      input_schema: %{
        federal_state_slug: {:required, :string, description: "Federal state slug"},
        years:
          {:required, {:array, :integer},
           min_items: 1, max_items: 5, description: "Years to check (array of integers)"}
      },
      annotations: %{read_only: true}
    )
  end

  # Statistical & Analysis Tools
  defp register_statistical_tools(frame) do
    frame
    |> register_tool("get_vacation_statistics",
      description: "Get vacation day statistics for a location",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["federal_state", "city", "school"]},
        year: {:required, :integer, min: 2020, max: 2030}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("compare_vacation_schedules",
      description: "Compare vacation schedules between multiple locations",
      input_schema: %{
        location_slugs:
          {:required, {:array, :string},
           min_items: 2, max_items: 5, description: "Array of location slugs to compare"},
        location_type: {:required, :string, enum: ["federal_state", "city", "school"]},
        year: {:required, :integer, min: 2020, max: 2030}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_school_year_info",
      description: "Get school year start and end dates",
      input_schema: %{
        federal_state_slug: {:required, :string, description: "Federal state slug"},
        year:
          {:required, :integer,
           min: 2020,
           max: 2030,
           description: "Calendar year (school year spans two calendar years)"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_bewegliche_ferientage",
      description: "Get flexible vacation day information for a school",
      input_schema: %{
        school_slug: {:required, :string, description: "School slug"},
        school_year:
          {:required, :string,
           pattern: "^\\d{4}/\\d{4}$", description: "School year (e.g., '2024/2025')"}
      },
      annotations: %{read_only: true}
    )
  end

  # Export Tools
  defp register_export_tools(frame) do
    frame
    |> register_tool("get_ical_url",
      description: "Generate iCal subscription URL for a location",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("export_periods_json",
      description: "Export periods as structured JSON",
      input_schema: %{
        location_slug: {:required, :string, description: "Location slug"},
        location_type: {:required, :string, enum: ["country", "federal_state", "city", "school"]},
        start_date: {:required, :string, pattern: "^\\d{4}-\\d{2}-\\d{2}$"},
        end_date: {:required, :string, pattern: "^\\d{4}-\\d{2}-\\d{2}$"},
        include_metadata:
          {:optional, :boolean,
           default: false, description: "Include additional metadata in export"}
      },
      annotations: %{read_only: true}
    )
  end

  # Search & Discovery Tools
  defp register_search_tools(frame) do
    frame
    |> register_tool("search_locations",
      description: "Search for any location by name",
      input_schema: %{
        query: {:required, :string, min: 2, description: "Search query (min 2 chars)"},
        type:
          {:optional, :string,
           enum: ["country", "federal_state", "county", "city", "school"],
           description: "Filter by location type"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("get_location_by_slug",
      description: "Get location details by slug",
      input_schema: %{
        slug: {:required, :string, description: "Location slug"}
      },
      annotations: %{read_only: true}
    )
    |> register_tool("validate_slug",
      description: "Check if a slug exists and get its type",
      input_schema: %{
        slug: {:required, :string, description: "Slug to validate"}
      },
      annotations: %{read_only: true}
    )
  end

  # Tool Handlers - Location Navigation

  def handle_tool("get_countries", _params, frame) do
    countries = Locations.list_countries()

    result =
      Enum.map(countries, fn country ->
        %{
          name: country.name,
          slug: country.slug,
          code: country.code
        }
      end)

    {:reply, result, frame}
  end

  def handle_tool("get_federal_states", %{country_slug: country_slug}, frame) do
    with {:ok, country} <- get_country_by_slug(country_slug) do
      states = Locations.list_federal_states(country)

      result =
        Enum.map(states, fn state ->
          %{
            name: state.name,
            slug: state.slug,
            code: state.code
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Country not found: #{country_slug}", frame}
    end
  end

  def handle_tool(
        "get_counties",
        %{country_slug: country_slug, federal_state_slug: state_slug},
        frame
      ) do
    with {:ok, _country, state} <- get_federal_state_and_country(country_slug, state_slug) do
      counties = Locations.list_counties(state)

      result =
        Enum.map(counties, fn county ->
          %{
            name: county.name,
            slug: county.slug,
            code: county.code
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Federal state not found: #{state_slug}", frame}
    end
  end

  def handle_tool(
        "get_cities_by_state",
        %{country_slug: country_slug, federal_state_slug: state_slug},
        frame
      ) do
    with {:ok, _country, state} <- get_federal_state_and_country(country_slug, state_slug) do
      cities = Locations.list_cities_of_federal_state(state)

      result =
        Enum.map(cities, fn city ->
          %{
            name: city.name,
            slug: city.slug,
            zip_codes: get_zip_codes(city)
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Federal state not found: #{state_slug}", frame}
    end
  end

  def handle_tool("get_cities_by_country", %{country_slug: country_slug}, frame) do
    with {:ok, country} <- get_country_by_slug(country_slug) do
      cities = Locations.list_cities_of_country(country)

      result =
        Enum.map(cities, fn city ->
          %{
            name: city.name,
            slug: city.slug,
            zip_codes: get_zip_codes(city)
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Country not found: #{country_slug}", frame}
    end
  end

  def handle_tool("get_schools_by_city", %{city_slug: city_slug}, frame) do
    with {:ok, city} <- get_city_by_slug(city_slug) do
      schools = Locations.list_schools_selective(city)

      result =
        Enum.map(schools, fn school ->
          %{
            name: school.name,
            slug: school.slug,
            street: school[:street],
            zip_code: school[:zip_code]
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "City not found: #{city_slug}", frame}
    end
  end

  def handle_tool(
        "get_schools_by_federal_state",
        %{country_slug: country_slug, federal_state_slug: state_slug},
        frame
      ) do
    with {:ok, _country, state} <- get_federal_state_and_country(country_slug, state_slug) do
      # Get all cities in the state
      cities = Locations.list_cities_of_federal_state(state)
      city_ids = Enum.map(cities, & &1.id)

      # Get all schools in those cities
      schools =
        Repo.all(
          from l in MehrSchulferien.Locations.Location,
            where: l.is_school == true and l.parent_location_id in ^city_ids,
            select: %{
              name: l.name,
              slug: l.slug,
              city_id: l.parent_location_id
            }
        )

      # Add city names
      city_map = Map.new(cities, fn city -> {city.id, city.name} end)

      result =
        Enum.map(schools, fn school ->
          %{
            name: school.name,
            slug: school.slug,
            city: city_map[school.city_id]
          }
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Federal state not found: #{state_slug}", frame}
    end
  end

  def handle_tool("get_location_hierarchy", %{location_slug: slug, location_type: type}, frame) do
    with {:ok, location} <- get_location_by_type(slug, type) do
      hierarchy = build_location_hierarchy(location)
      {:reply, hierarchy, frame}
    else
      {:error, :not_found} ->
        {:error, "Location not found: #{slug}", frame}
    end
  end

  # Tool Handlers - School Information

  def handle_tool("get_school_details", %{school_slug: school_slug}, frame) do
    with {:ok, school} <- get_school_by_slug(school_slug) do
      school = Repo.preload(school, [:address, :parent_location])

      result = %{
        name: school.name,
        slug: school.slug,
        type: get_school_type(school),
        address: format_address(school.address),
        contact: format_contact(school.address),
        metadata: format_school_metadata(school.address),
        location: %{
          city: school.parent_location && school.parent_location.name,
          city_slug: school.parent_location && school.parent_location.slug
        }
      }

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "School not found: #{school_slug}", frame}
    end
  end

  def handle_tool("search_schools", params, frame) do
    search_query = params.query

    base_query =
      from l in MehrSchulferien.Locations.Location,
        where: l.is_school == true and ilike(l.name, ^"%#{search_query}%"),
        limit: 50

    # Apply optional filters
    filtered_query =
      base_query
      |> maybe_filter_by_federal_state(params[:federal_state_slug])
      |> maybe_filter_by_city(params[:city_slug])

    schools = Repo.all(filtered_query) |> Repo.preload(:parent_location)

    result =
      Enum.map(schools, fn school ->
        %{
          name: school.name,
          slug: school.slug,
          city: school.parent_location && school.parent_location.name
        }
      end)

    {:reply, result, frame}
  end

  def handle_tool(
        "get_nearby_schools",
        %{school_slug: school_slug, distance_meters: distance},
        frame
      ) do
    with {:ok, school} <- get_school_by_slug(school_slug) do
      school = Repo.preload(school, :address)

      if school.address && school.address.lat && school.address.lon do
        nearby = Locations.list_nearby_schools(school, distance)

        result =
          Enum.map(nearby, fn s ->
            %{
              name: s.name,
              slug: s.slug,
              distance_meters: s.distance
            }
          end)

        {:reply, result, frame}
      else
        {:error, "School has no geographic coordinates", frame}
      end
    else
      {:error, :not_found} ->
        {:error, "School not found: #{school_slug}", frame}
    end
  end

  def handle_tool("get_schools_by_zip", %{zip_prefix: zip_prefix}, frame) do
    schools =
      Repo.all(
        from l in MehrSchulferien.Locations.Location,
          join: a in MehrSchulferien.Maps.Address,
          on: a.school_location_id == l.id,
          where: l.is_school == true and like(a.zip_code, ^"#{zip_prefix}%"),
          select: %{
            name: l.name,
            slug: l.slug,
            street: a.street,
            zip_code: a.zip_code,
            city: a.city
          },
          limit: 100
      )

    {:reply, schools, frame}
  end

  # Tool Handlers - Period Queries

  def handle_tool("get_vacations", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type),
         {:ok, start_date, end_date} <- parse_date_range(params) do
      location_ids = Locations.recursive_location_ids(location)

      periods =
        Periods.list_school_free_periods(location_ids, start_date, end_date)
        |> Repo.preload(:holiday_or_vacation_type)

      result = Enum.map(periods, &format_period/1)

      {:reply, result, frame}
    else
      {:error, reason} ->
        {:error, reason, frame}
    end
  end

  def handle_tool("get_public_holidays", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type) do
      {:ok, start_date} = Date.new(params.year, 1, 1)
      {:ok, end_date} = Date.new(params.year, 12, 31)

      location_ids = Locations.recursive_location_ids(location)

      periods =
        Periods.list_public_everybody_periods(location_ids, start_date, end_date)
        |> Repo.preload(:holiday_or_vacation_type)

      result = Enum.map(periods, &format_period/1)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Location not found: #{params.location_slug}", frame}
    end
  end

  def handle_tool("get_next_periods", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type) do
      count = params[:count] || 5
      today = DateHelpers.today_berlin()

      location_ids = Locations.recursive_location_ids(location)

      # Get periods for the next 2 years
      end_date = Date.add(today, 730)

      periods =
        Periods.list_school_free_periods(location_ids, today, end_date)
        |> Repo.preload(:holiday_or_vacation_type)
        |> Enum.take(count)

      result = Enum.map(periods, &format_period/1)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Location not found: #{params.location_slug}", frame}
    end
  end

  def handle_tool("get_current_periods", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type),
         {:ok, date} <- parse_or_default_date(params[:date]) do
      location_ids = Locations.recursive_location_ids(location)

      periods =
        Periods.list_school_free_periods(location_ids, date, date)
        |> Repo.preload(:holiday_or_vacation_type)

      result = Enum.map(periods, &format_period/1)

      {:reply, result, frame}
    else
      {:error, reason} ->
        {:error, reason, frame}
    end
  end

  # Tool Handlers - Bridge Days

  def handle_tool("get_bridge_days", %{federal_state_slug: state_slug, year: year}, frame) do
    with {:ok, country} <- get_country_by_slug("deutschland"),
         {:ok, state} <- get_federal_state_by_slug(state_slug, country) do
      location_ids = [country.id, state.id]
      {:ok, start_date} = Date.new(year, 1, 1)
      {:ok, end_date} = Date.new(year, 12, 31)

      periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = Grouping.group_by_interval(periods)

      bridge_days = []

      for num <- 1..4 do
        if bridge_day_map[num] do
          valid_bridge_days =
            bridge_day_map[num]
            |> Enum.filter(fn bridge_day ->
              all_periods = Grouping.list_periods_with_bridge_day(periods, bridge_day)
              BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
            end)
            |> Enum.map(fn bridge_day ->
              all_periods = Grouping.list_periods_with_bridge_day(periods, bridge_day)

              total_free =
                BridgeDayCalculations.calculate_total_consecutive_free_days(
                  bridge_day,
                  all_periods
                )

              gain =
                if num > 0 do
                  (total_free - num) / num * 100
                else
                  0
                end

              %{
                starts_on: bridge_day.starts_on,
                ends_on: bridge_day.ends_on,
                vacation_days_needed: num,
                total_free_days: total_free,
                efficiency_percentage: round(gain),
                connected_periods: Enum.map(all_periods, &format_period/1)
              }
            end)

          bridge_days ++ valid_bridge_days
        else
          bridge_days
        end
      end
      |> List.flatten()
      |> Enum.sort_by(& &1.efficiency_percentage, :desc)

      {:reply, bridge_days, frame}
    else
      {:error, :not_found} ->
        {:error, "Federal state not found: #{state_slug}", frame}
    end
  end

  def handle_tool(
        "check_bridge_days_availability",
        %{federal_state_slug: state_slug, years: years},
        frame
      ) do
    with {:ok, country} <- get_country_by_slug("deutschland"),
         {:ok, state} <- get_federal_state_by_slug(state_slug, country) do
      result =
        Enum.map(years, fn year ->
          has_bridge_days = BridgeDays.has_bridge_days?([country.id, state.id], year)
          %{year: year, has_bridge_days: has_bridge_days}
        end)

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Federal state not found: #{state_slug}", frame}
    end
  end

  # Tool Handlers - Statistics

  def handle_tool("get_vacation_statistics", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type) do
      {:ok, start_date} = Date.new(params.year, 1, 1)
      {:ok, end_date} = Date.new(params.year, 12, 31)

      location_ids = Locations.recursive_location_ids(location)

      vacations = Periods.list_school_free_periods(location_ids, start_date, end_date)
      holidays = Periods.list_public_everybody_periods(location_ids, start_date, end_date)

      vacation_days =
        vacations
        |> Enum.map(fn p -> Date.diff(p.ends_on, p.starts_on) + 1 end)
        |> Enum.sum()

      longest_vacation =
        vacations
        |> Enum.map(fn p -> Date.diff(p.ends_on, p.starts_on) + 1 end)
        |> Enum.max(fn -> 0 end)

      result = %{
        year: params.year,
        total_vacation_days: vacation_days,
        vacation_count: length(vacations),
        holiday_count: length(holidays),
        longest_vacation_days: longest_vacation,
        # Rough estimate
        school_days_estimate: 365 - vacation_days - 52 * 2
      }

      {:reply, result, frame}
    else
      {:error, :not_found} ->
        {:error, "Location not found: #{params.location_slug}", frame}
    end
  end

  def handle_tool("compare_vacation_schedules", params, frame) do
    year = params.year
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    schedules =
      Enum.map(params.location_slugs, fn slug ->
        with {:ok, location} <- get_location_by_type(slug, params.location_type) do
          location_ids = Locations.recursive_location_ids(location)

          periods =
            Periods.list_school_free_periods(location_ids, start_date, end_date)
            |> Repo.preload(:holiday_or_vacation_type)

          {:ok,
           %{
             location: slug,
             periods: Enum.map(periods, &format_period/1)
           }}
        else
          {:error, :not_found} -> {:error, slug}
        end
      end)

    # Check for errors
    errors =
      Enum.filter(schedules, fn
        {:error, _} -> true
        _ -> false
      end)

    if length(errors) > 0 do
      error_slugs = Enum.map(errors, fn {:error, slug} -> slug end)
      {:error, "Locations not found: #{Enum.join(error_slugs, ", ")}", frame}
    else
      schedules = Enum.map(schedules, fn {:ok, s} -> s end)

      # Find overlapping periods
      all_periods = Enum.flat_map(schedules, & &1.periods)
      overlaps = find_overlapping_periods(all_periods)

      result = %{
        schedules: schedules,
        overlapping_periods: overlaps,
        comparison_year: year
      }

      {:reply, result, frame}
    end
  end

  def handle_tool("get_school_year_info", %{federal_state_slug: _state_slug, year: year}, frame) do
    school_year = Periods.get_school_year_for_date(Date.new!(year, 8, 1))

    result = %{
      school_year: school_year,
      starts_approximately: "#{year}-08-01",
      ends_approximately: "#{year + 1}-07-31",
      note: "Exact dates vary by federal state and year"
    }

    {:reply, result, frame}
  end

  def handle_tool("get_bewegliche_ferientage", params, frame) do
    with {:ok, school} <- get_school_by_slug(params.school_slug) do
      school = Repo.preload(school, :parent_location)

      # Get federal state
      city = school.parent_location
      county = city && Repo.get(MehrSchulferien.Locations.Location, city.parent_location_id)

      federal_state =
        county && Repo.get(MehrSchulferien.Locations.Location, county.parent_location_id)

      if federal_state do
        used_days =
          Periods.count_bewegliche_ferientage_for_school_year(school.id, params.school_year)

        limit =
          case Periods.get_federal_state_ferientage_limit(federal_state.id, params.school_year) do
            nil -> nil
            record -> record.max_bewegliche_ferientage
          end

        result = %{
          school: school.name,
          school_year: params.school_year,
          used_days: used_days,
          max_days: limit || "No limit set",
          remaining_days: if(limit, do: limit - used_days, else: "Unknown")
        }

        {:reply, result, frame}
      else
        {:error, "Could not determine federal state for school", frame}
      end
    else
      {:error, :not_found} ->
        {:error, "School not found: #{params.school_slug}", frame}
    end
  end

  # Tool Handlers - Export

  def handle_tool("get_ical_url", params, frame) do
    base_url =
      Application.get_env(:mehr_schulferien, MehrSchulferienWeb.Endpoint)[:url][:host] ||
        "www.mehr-schulferien.de"

    url =
      case params.location_type do
        "school" ->
          "https://#{base_url}/api/v2/ical/schools/#{params.location_slug}"

        "city" ->
          "https://#{base_url}/api/v2/ical/cities/#{params.location_slug}"

        "federal_state" ->
          "https://#{base_url}/api/v2/ical/federal_states/#{params.location_slug}"

        "country" ->
          "https://#{base_url}/api/v2/ical/countries/#{params.location_slug}"

        _ ->
          nil
      end

    if url do
      {:reply, %{ical_url: url, format: "text/calendar"}, frame}
    else
      {:error, "Invalid location type for iCal export", frame}
    end
  end

  def handle_tool("export_periods_json", params, frame) do
    with {:ok, location} <- get_location_by_type(params.location_slug, params.location_type),
         {:ok, start_date} <- Date.from_iso8601(params.start_date),
         {:ok, end_date} <- Date.from_iso8601(params.end_date) do
      location_ids = Locations.recursive_location_ids(location)

      periods =
        Periods.list_school_free_periods(location_ids, start_date, end_date)
        |> Repo.preload(:holiday_or_vacation_type)

      result = %{
        location: %{
          name: location.name,
          slug: location.slug,
          type: get_location_type(location)
        },
        date_range: %{
          start: params.start_date,
          end: params.end_date
        },
        periods: Enum.map(periods, &format_period_with_metadata(&1, params[:include_metadata]))
      }

      {:reply, result, frame}
    else
      {:error, reason} ->
        {:error, reason, frame}
    end
  end

  # Tool Handlers - Search & Discovery

  def handle_tool("search_locations", params, frame) do
    search_query = params.query

    base_query =
      from l in MehrSchulferien.Locations.Location,
        where: ilike(l.name, ^"%#{search_query}%"),
        limit: 50

    filtered_query =
      case params[:type] do
        "country" -> from l in base_query, where: l.is_country == true
        "federal_state" -> from l in base_query, where: l.is_federal_state == true
        "county" -> from l in base_query, where: l.is_county == true
        "city" -> from l in base_query, where: l.is_city == true
        "school" -> from l in base_query, where: l.is_school == true
        _ -> base_query
      end

    locations = Repo.all(filtered_query)

    result =
      Enum.map(locations, fn loc ->
        %{
          name: loc.name,
          slug: loc.slug,
          type: get_location_type(loc)
        }
      end)

    {:reply, result, frame}
  end

  def handle_tool("get_location_by_slug", %{slug: slug}, frame) do
    try do
      location = Locations.get_location_by_slug!(slug)

      result = %{
        name: location.name,
        slug: location.slug,
        type: get_location_type(location),
        code: location.code
      }

      {:reply, result, frame}
    rescue
      Ecto.NoResultsError ->
        {:error, "Location not found: #{slug}", frame}
    end
  end

  def handle_tool("validate_slug", %{slug: slug}, frame) do
    try do
      location = Locations.get_location_by_slug!(slug)

      {:reply,
       %{
         valid: true,
         slug: slug,
         type: get_location_type(location),
         name: location.name
       }, frame}
    rescue
      Ecto.NoResultsError ->
        {:reply, %{valid: false, slug: slug}, frame}
    end
  end

  # Helper Functions

  defp get_country_by_slug(slug) do
    case Locations.get_country_by_slug(slug) do
      nil -> {:error, :not_found}
      country -> {:ok, country}
    end
  end

  defp get_federal_state_by_slug(slug, country) do
    case Locations.get_federal_state_by_slug(slug, country) do
      nil -> {:error, :not_found}
      state -> {:ok, state}
    end
  end

  defp get_federal_state_and_country(country_slug, state_slug) do
    result = Locations.get_federal_state_and_country_by_slug(country_slug, state_slug)

    case result do
      {country, state} -> {:ok, country, state}
      _ -> {:error, :not_found}
    end
  end

  defp get_city_by_slug(slug) do
    case Locations.get_city_by_slug(slug) do
      nil -> {:error, :not_found}
      city -> {:ok, city}
    end
  end

  defp get_school_by_slug(slug) do
    case Locations.get_school_by_slug(slug) do
      nil -> {:error, :not_found}
      school -> {:ok, school}
    end
  end

  defp get_location_by_type(slug, type) do
    location =
      try do
        case type do
          "country" -> Locations.get_country_by_slug(slug)
          "federal_state" -> get_federal_state_by_slug_safe(slug)
          "county" -> get_county_by_slug_safe(slug)
          "city" -> Locations.get_city_by_slug(slug)
          "school" -> Locations.get_school_by_slug(slug)
          _ -> nil
        end
      rescue
        _ -> nil
      end

    case location do
      nil -> {:error, :not_found}
      loc -> {:ok, loc}
    end
  end

  defp get_federal_state_by_slug_safe(slug) do
    query =
      from l in Location,
        where: l.slug == ^slug and l.is_federal_state == true

    Repo.one(query)
  end

  defp get_county_by_slug_safe(slug) do
    query =
      from l in Location,
        where: l.slug == ^slug and l.is_county == true

    Repo.one(query)
  end

  defp get_location_type(location) do
    cond do
      location.is_country -> "country"
      location.is_federal_state -> "federal_state"
      location.is_county -> "county"
      location.is_city -> "city"
      location.is_school -> "school"
      true -> "unknown"
    end
  end

  defp get_school_type(school) do
    if school.address && school.address.school_type do
      school.address.school_type
    else
      "Unknown"
    end
  end

  defp get_zip_codes(city) do
    city = Repo.preload(city, :zip_codes)
    Enum.map(city.zip_codes || [], & &1.value)
  end

  defp format_period(period) do
    %{
      name: period.holiday_or_vacation_type.name,
      slug: period.holiday_or_vacation_type.slug,
      starts_on: Date.to_iso8601(period.starts_on),
      ends_on: Date.to_iso8601(period.ends_on),
      days: Date.diff(period.ends_on, period.starts_on) + 1,
      is_vacation: period.is_school_vacation,
      is_holiday: period.is_public_holiday
    }
  end

  defp format_period_with_metadata(period, include_metadata) do
    base = format_period(period)

    if include_metadata do
      Map.merge(base, %{
        display_priority: period.display_priority,
        valid_for_students: period.is_valid_for_students,
        valid_for_everybody: period.is_valid_for_everybody,
        created_by: period.created_by_email_address
      })
    else
      base
    end
  end

  defp format_address(nil), do: nil

  defp format_address(address) do
    %{
      street: address.street,
      zip_code: address.zip_code,
      city: address.city,
      coordinates:
        if(address.lat && address.lon,
          do: %{
            latitude: address.lat,
            longitude: address.lon
          },
          else: nil
        )
    }
  end

  defp format_contact(nil), do: nil

  defp format_contact(address) do
    %{
      phone: address.phone_number,
      fax: address.fax_number,
      email: address.email_address,
      homepage: address.homepage_url
    }
  end

  defp format_school_metadata(nil), do: nil

  defp format_school_metadata(address) do
    %{
      official_id: address.official_id,
      student_count: address.students_count,
      founded_year: address.founded_year,
      description: address.description,
      wikipedia_url: address.wikipedia_url,
      instagram_url: address.instagram_url
    }
  end

  defp build_location_hierarchy(location) do
    location = Repo.preload(location, :parent_location)

    hierarchy = [
      %{
        name: location.name,
        slug: location.slug,
        type: get_location_type(location)
      }
    ]

    if location.parent_location do
      build_location_hierarchy(location.parent_location) ++ hierarchy
    else
      hierarchy
    end
  end

  defp parse_date_range(%{start_date: start_str, end_date: end_str}) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      {:ok, start_date, end_date}
    else
      _ -> {:error, "Invalid date format. Use YYYY-MM-DD"}
    end
  end

  defp parse_date_range(_) do
    # Default to current year if no dates provided
    today = DateHelpers.today_berlin()
    year = today.year
    {:ok, Date.new!(year, 1, 1), Date.new!(year, 12, 31)}
  end

  defp parse_or_default_date(nil), do: {:ok, DateHelpers.today_berlin()}

  defp parse_or_default_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:ok, date}
      _ -> {:error, "Invalid date format. Use YYYY-MM-DD"}
    end
  end

  defp find_overlapping_periods(_periods) do
    # Group periods by date range to find overlaps
    # This is a simplified implementation
    []
  end

  defp maybe_filter_by_federal_state(query, nil), do: query

  defp maybe_filter_by_federal_state(query, _state_slug) do
    # This would need proper implementation to filter by federal state
    query
  end

  defp maybe_filter_by_city(query, nil), do: query

  defp maybe_filter_by_city(query, city_slug) do
    city = Locations.get_city_by_slug(city_slug)

    if city do
      from l in query, where: l.parent_location_id == ^city.id
    else
      query
    end
  end
end
