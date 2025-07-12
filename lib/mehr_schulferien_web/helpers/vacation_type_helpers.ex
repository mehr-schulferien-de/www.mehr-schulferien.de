defmodule MehrSchulferienWeb.Helpers.VacationTypeHelpers do
  @moduledoc """
  Helper functions for vacation type overview pages.
  Provides SEO content, data fetching, and formatting functions.
  """

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
      keywords: "Herbsturlaub, Wanderurlaub, Herbstausflug, Erntedank, Kurzreise",
      description_suffix: "Goldene Herbstzeit für Wanderungen und Kurzreisen.",
      meta_focus: "Perfekt für Herbstwanderungen und Städtereisen in der bunten Jahreszeit.",
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

      earliest_date = Calendar.strftime(earliest.period.starts_on, "%d.%m.")
      latest_date = Calendar.strftime(latest.period.starts_on, "%d.%m.")

      "#{config.name} #{year} in Deutschland: Termine aller 16 Bundesländer von #{earliest_date} bis #{latest_date}. #{config.meta_focus}"
    end
  end

  @doc """
  Generate structured data for vacation type page
  """
  def generate_vacation_structured_data(vacation_type, year, states_data, conn) do
    config = get_vacation_config(vacation_type)

    # ItemList of all vacation periods
    item_list = %{
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => "#{config.name} #{year} - Alle Bundesländer",
      "description" => generate_meta_description(vacation_type, year, states_data),
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
              },
              "url" =>
                "https://www.mehr-schulferien.de" <>
                  Phoenix.Controller.current_path(conn) <>
                  "##{state.slug}"
            }
          }
        end)
    }

    # FAQ Schema
    faq = %{
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => [
        %{
          "@type" => "Question",
          "name" => "Wann sind #{config.name} #{year} in Deutschland?",
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" => generate_faq_answer_dates(config, year, states_data)
          }
        },
        %{
          "@type" => "Question",
          "name" => "Welches Bundesland hat zuerst #{config.name} #{year}?",
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" => generate_faq_answer_first_state(states_data)
          }
        },
        %{
          "@type" => "Question",
          "name" => "Wie lange dauern die #{config.name} #{year}?",
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" => generate_faq_answer_duration(config, states_data)
          }
        }
      ]
    }

    %{item_list: item_list, faq: faq}
  end

  @doc """
  Format vacation table data for display
  """
  def format_vacation_table_data(states_data) do
    Enum.map(states_data, fn %{state: state, period: period, duration: duration} ->
      %{
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

  # Private helper functions

  defp generate_faq_answer_dates(config, year, states_data) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Termine für #{config.name} #{year} stehen noch nicht fest."
    else
      earliest = List.first(valid_periods)
      latest = Enum.max_by(valid_periods, fn %{period: p} -> p.ends_on end)

      "Die #{config.name} #{year} beginnen am #{Calendar.strftime(earliest.period.starts_on, "%d.%m.%Y")} " <>
        "in #{earliest.state.name} und enden am #{Calendar.strftime(latest.period.ends_on, "%d.%m.%Y")} " <>
        "in #{latest.state.name}."
    end
  end

  defp generate_faq_answer_first_state(states_data) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Termine stehen noch nicht fest."
    else
      first = List.first(valid_periods)

      "#{first.state.name} beginnt als erstes Bundesland am #{Calendar.strftime(first.period.starts_on, "%d.%m.%Y")}."
    end
  end

  defp generate_faq_answer_duration(config, states_data) do
    durations =
      states_data
      |> Enum.filter(&(&1.period != nil))
      |> Enum.map(& &1.duration)
      |> Enum.uniq()
      |> Enum.sort()

    case durations do
      [] ->
        "Die Dauer der #{config.name} steht noch nicht fest."

      [single] ->
        "Die #{config.name} dauern in allen Bundesländern #{single} Tage."

      multiple ->
        min_days = List.first(multiple)
        max_days = List.last(multiple)

        "Die #{config.name} dauern zwischen #{min_days} und #{max_days} Tagen, je nach Bundesland."
    end
  end
end
