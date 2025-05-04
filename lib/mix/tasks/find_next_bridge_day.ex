defmodule Mix.Tasks.FindNextBridgeDay do
  @moduledoc """
  Finds the next available bridge day for a given federal state.

  ## Usage

      mix find_next_bridge_day <federal_state_slug> [<date>] [<days_count>]

  ## Examples

      # Find the next bridge day for Hamburg from today
      mix find_next_bridge_day hamburg

      # Find the next bridge day for Hamburg from a specific date
      mix find_next_bridge_day hamburg 2025-04-04

      # Find the next 2-day bridge day for Hamburg from a specific date
      mix find_next_bridge_day hamburg 2025-04-04 2
  """
  use Mix.Task

  alias MehrSchulferien.{BridgeDays, Locations, Calendars.DateHelpers}

  @country_slug "d"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    # Parse arguments
    {federal_state_slug, date, days_count} = parse_args(args)

    # Get the country and federal state
    country = Locations.get_country_by_slug!(@country_slug)

    case find_federal_state(country, federal_state_slug) do
      nil ->
        display_available_federal_states(country)

      federal_state ->
        find_and_display_bridge_day(federal_state, date, days_count)
    end
  end

  defp parse_args(args) do
    federal_state_slug = Enum.at(args, 0)
    date_string = Enum.at(args, 1)
    days_count_string = Enum.at(args, 2)

    date =
      if date_string do
        case Date.from_iso8601(date_string) do
          {:ok, date} -> date
          _ -> DateHelpers.today_berlin()
        end
      else
        DateHelpers.today_berlin()
      end

    days_count =
      if days_count_string do
        case Integer.parse(days_count_string) do
          {count, _} -> count
          _ -> 1
        end
      else
        1
      end

    {federal_state_slug, date, days_count}
  end

  defp find_federal_state(_country, nil), do: nil

  defp find_federal_state(country, federal_state_slug) do
    try do
      Locations.get_federal_state_by_slug!(federal_state_slug, country)
    rescue
      _ -> nil
    end
  end

  defp find_and_display_bridge_day(federal_state, date, days_count) do
    bridge_day = BridgeDays.find_next_bridge_day(federal_state, date, days_count)

    if bridge_day do
      days_text = if days_count == 1, do: "Tag", else: "Tage"

      IO.puts("""

      Nächster Brückentag für #{federal_state.name}:

      Datum: #{Date.to_string(bridge_day.starts_on)} bis #{Date.to_string(bridge_day.ends_on)}
      Dauer: #{bridge_day.number_days} #{days_text}

      """)
    else
      IO.puts(
        "\nKein Brückentag mit #{days_count} Tagen für #{federal_state.name} in den nächsten 2 Jahren gefunden.\n"
      )
    end
  end

  defp display_available_federal_states(country) do
    federal_states = Locations.list_federal_states(country)

    IO.puts("\nVerfügbare Bundesländer:")

    Enum.each(federal_states, fn federal_state ->
      IO.puts("  #{federal_state.slug} - #{federal_state.name}")
    end)

    IO.puts("\nBeispielaufruf: mix find_next_bridge_day hamburg\n")
  end
end
