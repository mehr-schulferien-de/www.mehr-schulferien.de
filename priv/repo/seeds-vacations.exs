# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds-vacations.exs

defmodule M do
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Calendars

  def parse_the_csv(year) do
    CSV.decode(
      File.stream!(
        "priv/repo/seeds.d/" <>
          Integer.to_string(year) <> "-" <> Integer.to_string(year + 1) <> ".csv"
      ),
      headers: true
    )
    |> Enum.each(fn x ->
      {:ok, line} = x

      %{"Land;Herbst;Weihnachten;Winter;Ostern/Frühjahr;Himmelfahrt/Pfingsten;Sommer" => value} =
        line

      vacations = String.split(value, ";")
      [federal_state_name, herbst, weihnachten, winter, ostern, pfingsten, sommer] = vacations
      IO.puts(federal_state_name)

      compute_vacation_date(federal_state_name, "Herbst", herbst, year)
      compute_vacation_date(federal_state_name, "Weihnachten", weihnachten, year)
      compute_vacation_date(federal_state_name, "Winter", winter, year)
      compute_vacation_date(federal_state_name, "Ostern/Frühjahr", ostern, year)
      compute_vacation_date(federal_state_name, "Himmelfahrt/Pfingsten", pfingsten, year)
      compute_vacation_date(federal_state_name, "Sommer", sommer, year)
      IO.puts(" ")
    end)
  end

  def compute_vacation_date(federal_state_name, vacation_type, vacation_date, year) do
    vacation_date
    |> String.replace(" – ", "x", global: true)
    |> String.replace(" - ", "x", global: true)
    |> String.replace("x", "-", global: true)
    |> String.replace("  ", " ", global: true)
    |> String.replace("/", " ", global: true)
    |> String.split(" ")
    |> Enum.each(fn vacation_date ->
      if String.length(vacation_date) > 2 do
        create_vacation_date(federal_state_name, vacation_type, vacation_date, year)
      end
    end)
  end

  def create_vacation_date(federal_state_name, vacation_type, vacation_date, year) do
    [starts_at, ends_at] =
      case String.split(vacation_date, "-") do
        [starts_at, ends_at] ->
          adds_year_to_date(starts_at, ends_at, vacation_type, year)

        [starts_at] ->
          adds_year_to_date(starts_at, starts_at, vacation_type, year)
      end

    starts_at = german_string_to_date(starts_at)
    ends_at = german_string_to_date(ends_at)

    # Find FederalState
    #
    query =
      from(l in Location,
        where: l.name == ^federal_state_name,
        where: l.is_federal_state == true,
        limit: 1
      )

    federal_state = Repo.one(query)

    # Find holiday_or_vacation_type
    #
    query =
      from(l in HolidayOrVacationType,
        where: l.name == ^vacation_type,
        where: l.country_location_id == ^federal_state.parent_location_id,
        limit: 1
      )

    holiday_or_vacation_type = Repo.one(query)

    IO.puts(
      federal_state.name <>
        " => " <>
        holiday_or_vacation_type.name <>
        ": " <>
        Date.to_string(starts_at) <>
        " - " <> Date.to_string(ends_at)
    )
    
    Calendars.create_period(%{
      author_email_address: "sw@wintermeyer-consulting.de",
      starts_on: starts_at,
      ends_on: ends_at,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id
    })
  end

  def adds_year_to_date(starts_at, ends_at, vacation_type, year) do
    case vacation_type do
      "Herbst" ->
        [starts_at <> Integer.to_string(year), ends_at <> Integer.to_string(year)]

      "Weihnachten" ->
        [starts_at <> Integer.to_string(year), ends_at <> Integer.to_string(year + 1)]

      _ ->
        [starts_at <> Integer.to_string(year + 1), ends_at <> Integer.to_string(year + 1)]
    end
  end

  def german_string_to_date(german_string) do
    [day, month, year] = String.split(german_string, ".")

    {:ok, new_date} =
      Date.from_erl({String.to_integer(year), String.to_integer(month), String.to_integer(day)})

    new_date
  end

  def generate_weekend_periods(year) do
    # Find Germany
    #
    query =
      from(l in Location,
        where: l.name == "Deutschland",
        where: l.is_country == true,
        limit: 1
      )

    country = Repo.one(query)

    # Find holiday_or_vacation_type
    #
    query =
      from(l in HolidayOrVacationType,
        where: l.name == "Wochenende",
        where: l.country_location_id == ^country.id,
        limit: 1
      )

    holiday_or_vacation_type = Repo.one(query)

    {:ok, starts_on} = Date.from_erl({year,1,1})
    {:ok, ends_on} = Date.from_erl({year,12,31})
    range = Date.range(starts_on,ends_on)
    Enum.each range, fn day -> 
      if Date.day_of_week(day) == 6 do
        Calendars.create_period(%{
          author_email_address: "sw@wintermeyer-consulting.de",
          starts_on: day,
          ends_on: Date.add(day,1),
          location_id: country.id,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id
        })
      end
    end
  end
end

Enum.each [2020,2021,2022], fn year ->
  M.parse_the_csv(year)
  M.generate_weekend_periods(year)
end 
