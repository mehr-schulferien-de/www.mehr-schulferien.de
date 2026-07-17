defmodule MehrSchulferienWeb.Helpers.VacationTypeHelpers do
  @moduledoc """
  Helper functions for vacation type overview pages.
  Provides SEO content, data fetching, and formatting functions.
  """

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.{Locations, Periods}

  @vacation_configs %{
    "sommer" => %{
      name: "Sommerferien",
      slug: "sommer",
      keywords: "Sommerurlaub, Familienurlaub, Schulferien Sommer, Strandurlaub, Reisezeit",
      description_suffix: "Die großen Ferien für Familienurlaub, Reisen und Erholung.",
      meta_focus:
        "Planen Sie Ihren Sommerurlaub optimal mit allen Ferienterminen der 16 Bundesländer.",
      start_month: 6,
      start_day: 15,
      duration_days: 95
    },
    "ostern" => %{
      name: "Osterferien",
      slug: "ostern",
      keywords: "Osterurlaub, Frühlingsferien, Osterausflug, Ostereiersuche, Kurzurlaub",
      description_suffix: "Frühlingsferien rund um das Osterfest.",
      meta_focus: "Nutzen Sie die Osterferien für Frühlingsausflüge und Kurzurlaube.",
      start_month: 3,
      start_day: 15,
      duration_days: 35
    },
    "herbst" => %{
      name: "Herbstferien",
      slug: "herbst",
      keywords:
        "Herbsturlaub, Wanderurlaub, Herbstausflug, Erntedank, Kurzreise, Herbstferien 2025, Herbstferien 2026, wann sind Herbstferien, Herbstferien Deutschland, Herbstferien Termine",
      description_suffix: "Goldene Herbstzeit für Wanderungen und Kurzreisen.",
      meta_focus:
        "Perfekt für Herbstwanderungen und Städtereisen in der bunten Jahreszeit. Vergleichen Sie alle 16 Bundesländer und planen Sie Ihren Herbsturlaub optimal.",
      start_month: 9,
      start_day: 25,
      duration_days: 35
    },
    "weihnachten" => %{
      name: "Weihnachtsferien",
      slug: "weihnachten",
      keywords: "Weihnachtsurlaub, Winterurlaub, Silvesterurlaub, Skiurlaub, Weihnachtsmärkte",
      description_suffix: "Ferien über Weihnachten und Silvester.",
      meta_focus:
        "Weihnachtszeit und Jahreswechsel - planen Sie Winterurlaub oder Familienbesuche.",
      start_month: 12,
      start_day: 20,
      duration_days: 25
    },
    "winter" => %{
      name: "Winterferien",
      slug: "winter",
      keywords: "Winterurlaub, Skiferien, Skiurlaub, Winterferien, Faschingsferien",
      description_suffix: "Skiferien und Winterurlaub in den Bergen.",
      meta_focus: "Ideal für Wintersport und Skiurlaub in den Alpen oder Mittelgebirgen.",
      start_month: 1,
      start_day: 25,
      duration_days: 35
    },
    "pfingsten" => %{
      name: "Pfingstferien",
      slug: "pfingsten",
      keywords: "Pfingsturlaub, Kurzurlaub, verlängertes Wochenende, Städtereise, Pfingstausflug",
      description_suffix: "Kurze Ferien um Pfingsten für Ausflüge.",
      meta_focus: "Nutzen Sie die Pfingstferien für Kurzurlaube und verlängerte Wochenenden.",
      start_month: 5,
      start_day: 15,
      duration_days: 25
    }
  }

  @doc """
  Get configuration for a vacation type
  """
  def get_vacation_config(vacation_type) do
    Map.get(@vacation_configs, vacation_type, @vacation_configs["sommer"])
  end

  @doc """
  Fetch vacation data for all federal states for a specific vacation type and year
  """
  def fetch_vacation_data_for_type(vacation_type, year) do
    config = get_vacation_config(vacation_type)

    # Get Germany
    country = Locations.get_country_by_slug!("d")

    # Get all federal states
    federal_states = Locations.list_federal_states(country)

    # Calculate date range for the vacation period - use the whole year to find all vacation periods
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    # Fetch vacation periods for all states
    Enum.map(federal_states, fn state ->
      location_ids = [state.id]

      # Get vacation periods for this state
      periods =
        Periods.list_school_vacation_periods(location_ids, start_date, end_date)
        |> Enum.filter(fn period ->
          period.holiday_or_vacation_type &&
            (String.downcase(period.holiday_or_vacation_type.slug) == config.slug ||
               String.contains?(
                 String.downcase(period.holiday_or_vacation_type.name),
                 config.slug
               ))
        end)
        |> Enum.sort_by(& &1.starts_on)

      # Get the main vacation period (usually there's only one per type per year)
      main_period = List.first(periods)

      %{
        state: state,
        period: main_period,
        duration:
          if(main_period, do: Date.diff(main_period.ends_on, main_period.starts_on) + 1, else: 0)
      }
    end)
    |> Enum.sort_by(fn %{period: period} ->
      if period, do: period.starts_on, else: ~D[2099-12-31]
    end)
  end

  @doc """
  Generate meta description for vacation type overview page
  """
  def generate_meta_description(vacation_type, year, states_data) do
    config = get_vacation_config(vacation_type)

    # Find earliest and latest dates
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "#{config.name} #{year} in Deutschland. #{config.description_suffix}"
    else
      earliest = List.first(valid_periods)
      latest = Enum.max_by(valid_periods, fn %{period: p} -> p.starts_on end)

      earliest_date = DateHelpers.german_date(earliest.period.starts_on)
      latest_date = DateHelpers.german_date(latest.period.starts_on)
      earliest_state = earliest.state.name
      latest_state = latest.state.name

      "#{config.name} #{year}: Von #{earliest_date} (#{earliest_state}) bis #{latest_date} (#{latest_state}) | Alle 16 Bundesländer im Vergleich. Jetzt Urlaub planen!"
    end
  end

  @doc """
  Generate structured data for vacation type page with both current and next year
  """
  def generate_vacation_structured_data(
        vacation_type,
        current_year,
        current_year_data,
        next_year_data,
        conn
      ) do
    config = get_vacation_config(vacation_type)
    next_year = current_year + 1

    # ItemList for current year
    current_year_item_list =
      generate_year_item_list(config, current_year, current_year_data, conn)

    # ItemList for next year
    next_year_item_list = generate_year_item_list(config, next_year, next_year_data, conn)

    [current_year_item_list, next_year_item_list]
  end

  defp generate_year_item_list(config, year, states_data, _conn) do
    %{
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => "#{config.name} #{year} - Alle Bundesländer",
      "description" => generate_meta_description(config.slug, year, states_data),
      "itemListElement" =>
        states_data
        |> Enum.filter(&(&1.period != nil))
        |> Enum.with_index(1)
        |> Enum.map(fn {%{state: state, period: period, duration: duration}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "item" => %{
              "@type" => "Event",
              "name" => "#{config.name} #{state.name} #{year}",
              "startDate" => period.starts_on,
              "endDate" => period.ends_on,
              "duration" => "P#{duration}D",
              "location" => %{
                "@type" => "Place",
                "name" => state.name,
                "address" => %{
                  "@type" => "PostalAddress",
                  "addressRegion" => state.name,
                  "addressCountry" => "DE"
                }
              }
            }
          }
        end)
    }
  end

  @doc """
  Format vacation table data for display
  """
  def format_vacation_table_data(states_data) do
    Enum.map(states_data, fn %{state: state, period: period, duration: duration} ->
      %{
        state: state,
        state_name: state.name,
        state_code: state.code,
        state_slug: state.slug,
        start_date: if(period, do: Calendar.strftime(period.starts_on, "%d.%m.%Y"), else: "-"),
        end_date: if(period, do: Calendar.strftime(period.ends_on, "%d.%m.%Y"), else: "-"),
        duration: duration,
        period: period
      }
    end)
  end
end
