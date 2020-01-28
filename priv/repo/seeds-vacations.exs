# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds-vacations.exs

defmodule M do
  def parse_the_csv do
    year = 2020
    CSV.decode(File.stream!("priv/repo/seeds.d/" <> Integer.to_string(year) <> "-" <> Integer.to_string(year + 1) <> ".csv"), headers: true)
    |> Enum.each(fn x ->
      {:ok, line} = x

      %{"Land;Herbst;Weihnachten;Winter;Ostern/Frühjahr;Himmelfahrt/Pfingsten;Sommer" => value} =
        line

      vacations = String.split(value, ";")
      [federal_state_name, herbst, weihnachten, winter, ostern, pfingsten, sommer] = vacations
      IO.puts(federal_state_name)

      compute_vacation_date(federal_state_name, "Herbst", herbst)
      compute_vacation_date(federal_state_name, "Weihnachten", weihnachten)
      compute_vacation_date(federal_state_name, "Winter", winter)
      compute_vacation_date(federal_state_name, "Ostern/Frühjahr", ostern)
      compute_vacation_date(federal_state_name, "Himmelfahrt/Pfingsten", pfingsten)
      compute_vacation_date(federal_state_name, "Sommer", sommer)
      IO.puts(" ")
    end)
  end

  def compute_vacation_date(federal_state_name, vacation_type, vacation_date) do
    vacation_date
    |> String.replace(" – ", "x", global: true)
    |> String.replace(" - ", "x", global: true)
    |> String.replace("x", "-", global: true)
    |> String.replace("  ", " ", global: true)
    |> String.replace("/", " ", global: true)
    |> String.split(" ")
    |> Enum.each(fn vacation_date ->
      if String.length(vacation_date) > 2 do
        create_vacation_date(federal_state_name, vacation_type, vacation_date)
      end
    end)
  end

  def create_vacation_date(federal_state_name, vacation_type, vacation_date) do
    case String.split(vacation_date, "-") do
      [starts_at, ends_at] ->
        IO.puts(vacation_type <> ": " <> starts_at <> " - " <> ends_at)

      [starts_at] ->
        IO.puts(vacation_type <> ": " <> starts_at <> " - " <> starts_at)
    end
  end
end

M.parse_the_csv()
