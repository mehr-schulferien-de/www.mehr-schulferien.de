# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds-public-holidays.exs

defmodule M do
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def import_json(year) do
    json_public_holidays = "priv/repo/seeds.d/" <> Integer.to_string(year) <> ".json" |> File.read!() |> Poison.decode!()

    query =
      from(l in Location,
        where: l.is_federal_state == true,
        where: l.parent_location_id == 1
      )

    federal_states = Repo.all(query)

    federal_states
    |> Enum.each(fn federal_state -> 
      Map.keys(json_public_holidays[federal_state.code]) 
        |> Enum.each(fn json_public_holiday_name ->
          json_date = json_public_holidays[federal_state.code][json_public_holiday_name]["datum"]
          json_hinweis = json_public_holidays[federal_state.code][json_public_holiday_name]["hinweis"]
          case json_hinweis do
            "" ->
              Calendars.create_holiday_or_vacation_type
            _ ->
          end
          unless json_hinweis == "" do
            IO.puts federal_state.name

            IO.puts json_public_holiday_name
            IO.puts json_date
            IO.puts json_hinweis
            IO.puts ""
          end
        end)
      # IO.puts json_public_holidays[federal_state.code]["Neujahrstag"]["datum"]
    end)

    def first_or_create(public_holiday_type) do
      query =
        from(l in HolidayOrVacationType,
          where: l.name == ^public_holiday_type,
          where: l.country_location_id == 1,
          limit: 1
        )

      holiday_or_vacation_type =
        case Repo.one(query) do
          nil ->
            {:ok, holiday_or_vacation_type} =
              Calendars.create_holiday_or_vacation_type(%
                name: public_holiday_type,
                country_location_id: 1
              )

            holiday_or_vacation_type

          holiday_or_vacation_type ->
            holiday_or_vacation_type
        end
      
    end

    # json_public_holidays
    #   |> Enum.each(fn json_federal_state ->

    #   end)
  end

end

Enum.each [2023], fn year ->
  M.import_json(year)
end 