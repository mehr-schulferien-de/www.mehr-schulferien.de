# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds-vacations.exs


defmodule M do

  def parse_the_csv do
    year = 2020

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

  def create_vacation_date(_federal_state_name, vacation_type, vacation_date, year) do
    [starts_at, ends_at] =
      case String.split(vacation_date, "-") do
        [starts_at, ends_at] ->
          adds_year_to_date(starts_at, ends_at, vacation_type, year)

        [starts_at] ->
          adds_year_to_date(starts_at, starts_at, vacation_type, year)
      end

      starts_at = german_string_to_date(starts_at)
      ends_at = german_string_to_date(ends_at)

    IO.puts(
      vacation_type <>
        ": " <>
        Date.to_string(starts_at) <>
        " - " <> Date.to_string(ends_at)
    )
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
    {:ok, new_date} = Date.from_erl({String.to_integer(year), String.to_integer(month), String.to_integer(day)})
    new_date
  end
end

M.parse_the_csv()
