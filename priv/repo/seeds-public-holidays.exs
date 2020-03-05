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
    json_public_holidays =
      ("priv/repo/seeds.d/" <> Integer.to_string(year) <> ".json")
      |> File.read!()
      |> Jason.decode!()

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

        json_hinweis =
          json_public_holidays[federal_state.code][json_public_holiday_name]["hinweis"]

        unless json_hinweis == "" do
          school_vacation =
            json_public_holidays[federal_state.code][json_public_holiday_name]["school_vacation"]

          if school_vacation == true do
            public_holiday_type = first_or_create(json_public_holiday_name)

            Calendars.create_period(%{
              location_id: federal_state.id,
              created_by_email_address: "sw@wintermeyer-consulting.de",
              starts_on: json_date,
              ends_on: json_date,
              holiday_or_vacation_type_id: public_holiday_type.id,
              html_class: "info",
              is_public_holiday: true,
              is_valid_for_everybody: false,
              is_valid_for_students: true,
              memo: json_hinweis,
              display_priority: 10
            })
          end
        else
          itscomplicated =
            json_public_holidays[federal_state.code][json_public_holiday_name]["itscomplicated"]

          unless itscomplicated == true do
            public_holiday_type = first_or_create(json_public_holiday_name)

            Calendars.create_period(%{
              location_id: federal_state.id,
              created_by_email_address: "sw@wintermeyer-consulting.de",
              starts_on: json_date,
              ends_on: json_date,
              holiday_or_vacation_type_id: public_holiday_type.id,
              html_class: "info",
              is_public_holiday: true,
              is_valid_for_everybody: true,
              is_valid_for_students: true,
              display_priority: 11
            })
          end
        end
      end)
    end)
  end

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
            Calendars.create_holiday_or_vacation_type(%{
              name: public_holiday_type,
              country_location_id: 1,
              html_class: "info",
              default_display_priority: 10
            })

          holiday_or_vacation_type

        holiday_or_vacation_type ->
          holiday_or_vacation_type
      end
  end
end

Enum.each([2020, 2021, 2022], fn year ->
  M.import_json(year)
end)
