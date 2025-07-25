defmodule MehrSchulferien.Repo.Migrations.Add2028WeekendPeriods do
  use Ecto.Migration

  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def up do
    # Get the Deutschland location and Wochenende holiday type
    deutschland = Repo.one!(from(l in Location, where: l.slug == "d"))
    wochenende_type = Repo.one!(from(h in HolidayOrVacationType, where: h.slug == "wochenende"))

    # Check if weekends for 2028 already exist
    existing_count =
      from(p in Period,
        where: p.location_id == ^deutschland.id,
        where: p.holiday_or_vacation_type_id == ^wochenende_type.id,
        where: fragment("EXTRACT(year FROM ?) = ?", p.starts_on, 2028)
      )
      |> Repo.aggregate(:count, :id)

    if existing_count > 0 do
      IO.puts("Skipping 2028 weekend creation - #{existing_count} weekends already exist")
    else
      # Generate all weekend periods for 2028
      weekend_periods_2028 = generate_weekend_periods(2028)

      # Insert weekend periods in batches
      Enum.chunk_every(weekend_periods_2028, 50)
      |> Enum.each(fn batch ->
        periods_data =
          Enum.map(batch, fn {starts_on, ends_on} ->
            %{
              starts_on: starts_on,
              ends_on: ends_on,
              is_public_holiday: false,
              is_school_vacation: false,
              is_valid_for_everybody: true,
              is_valid_for_students: false,
              is_listed_below_month: true,
              html_class: "info",
              display_priority: 5,
              location_id: deutschland.id,
              holiday_or_vacation_type_id: wochenende_type.id,
              created_by_email_address: "migration@mehr-schulferien.de",
              memo: nil,
              inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
              updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
            }
          end)

        Repo.insert_all(Period, periods_data)
      end)
    end
  end

  def down do
    # Remove all weekend periods for 2028
    deutschland = Repo.one!(from(l in Location, where: l.slug == "d"))
    wochenende_type = Repo.one!(from(h in HolidayOrVacationType, where: h.slug == "wochenende"))

    from(p in Period,
      where: p.location_id == ^deutschland.id,
      where: p.holiday_or_vacation_type_id == ^wochenende_type.id,
      where: fragment("EXTRACT(year FROM ?) = ?", p.starts_on, 2028)
    )
    |> Repo.delete_all()
  end

  # Generate weekend periods for a given year
  defp generate_weekend_periods(year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    start_date
    |> Date.range(end_date)
    # Saturday = 6
    |> Enum.filter(&(Date.day_of_week(&1) == 6))
    |> Enum.map(fn saturday ->
      sunday = Date.add(saturday, 1)
      {saturday, sunday}
    end)
  end
end
