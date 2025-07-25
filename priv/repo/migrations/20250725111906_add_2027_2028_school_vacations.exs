defmodule MehrSchulferien.Repo.Migrations.Add20272028SchoolVacations do
  use Ecto.Migration

  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def up do
    # Define the vacation periods for each federal state for the 2027/2028 school year
    # Based on KMK (Kultusministerkonferenz) official data
    vacation_data = [
      # Baden-Württemberg
      {"baden-wuerttemberg", "herbst", ~D[2027-11-02], ~D[2027-11-06]},
      {"baden-wuerttemberg", "weihnachten", ~D[2027-12-23], ~D[2028-01-08]},
      {"baden-wuerttemberg", "ostern", ~D[2028-04-18], ~D[2028-04-22]},
      {"baden-wuerttemberg", "himmelfahrt-pfingsten", ~D[2028-06-06], ~D[2028-06-17]},
      {"baden-wuerttemberg", "sommer", ~D[2028-07-27], ~D[2028-09-09]},

      # Bayern
      {"bayern", "herbst", ~D[2027-11-02], ~D[2027-11-05]},
      {"bayern", "weihnachten", ~D[2027-12-24], ~D[2028-01-07]},
      {"bayern", "winter", ~D[2028-02-28], ~D[2028-03-03]},
      {"bayern", "ostern", ~D[2028-04-10], ~D[2028-04-21]},
      {"bayern", "himmelfahrt-pfingsten", ~D[2028-06-06], ~D[2028-06-16]},
      {"bayern", "sommer", ~D[2028-07-31], ~D[2028-09-11]},

      # Berlin
      {"berlin", "herbst", ~D[2027-10-11], ~D[2027-10-23]},
      {"berlin", "weihnachten", ~D[2027-12-22], ~D[2027-12-31]},
      {"berlin", "winter", ~D[2028-01-31], ~D[2028-02-05]},
      {"berlin", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"berlin", "sommer", ~D[2028-07-01], ~D[2028-08-12]},

      # Brandenburg
      {"brandenburg", "herbst", ~D[2027-10-11], ~D[2027-10-23]},
      {"brandenburg", "weihnachten", ~D[2027-12-23], ~D[2027-12-31]},
      {"brandenburg", "winter", ~D[2028-01-31], ~D[2028-02-05]},
      {"brandenburg", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"brandenburg", "sommer", ~D[2028-06-29], ~D[2028-08-12]},

      # Bremen
      {"bremen", "herbst", ~D[2027-10-18], ~D[2027-10-30]},
      {"bremen", "weihnachten", ~D[2027-12-23], ~D[2028-01-08]},
      {"bremen", "winter", ~D[2028-01-31], ~D[2028-02-01]},
      {"bremen", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"bremen", "sommer", ~D[2028-07-20], ~D[2028-08-30]},

      # Hamburg
      {"hamburg", "herbst", ~D[2027-10-11], ~D[2027-10-22]},
      {"hamburg", "weihnachten", ~D[2027-12-20], ~D[2027-12-31]},
      {"hamburg", "fruehjahr", ~D[2028-03-06], ~D[2028-03-17]},
      {"hamburg", "himmelfahrt", ~D[2028-05-22], ~D[2028-05-26]},
      {"hamburg", "sommer", ~D[2028-07-03], ~D[2028-08-11]},

      # Hessen
      {"hessen", "herbst", ~D[2027-10-04], ~D[2027-10-16]},
      {"hessen", "weihnachten", ~D[2027-12-23], ~D[2028-01-11]},
      {"hessen", "ostern", ~D[2028-04-03], ~D[2028-04-14]},
      {"hessen", "sommer", ~D[2028-07-03], ~D[2028-08-11]},

      # Mecklenburg-Vorpommern
      {"mecklenburg-vorpommern", "herbst", ~D[2027-10-16], ~D[2027-10-23]},
      {"mecklenburg-vorpommern", "herbst", ~D[2027-11-25], ~D[2027-11-26]},
      {"mecklenburg-vorpommern", "weihnachten", ~D[2027-12-23], ~D[2028-01-04]},
      {"mecklenburg-vorpommern", "winter", ~D[2028-02-05], ~D[2028-02-17]},
      {"mecklenburg-vorpommern", "ostern", ~D[2028-04-10], ~D[2028-04-19]},
      {"mecklenburg-vorpommern", "himmelfahrt", ~D[2028-06-02], ~D[2028-06-06]},
      {"mecklenburg-vorpommern", "sommer", ~D[2028-06-26], ~D[2028-08-05]},

      # Niedersachsen
      {"niedersachsen", "herbst", ~D[2027-10-16], ~D[2027-10-30]},
      {"niedersachsen", "weihnachten", ~D[2027-12-23], ~D[2028-01-08]},
      {"niedersachsen", "winter", ~D[2028-01-31], ~D[2028-02-01]},
      {"niedersachsen", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"niedersachsen", "sommer", ~D[2028-07-20], ~D[2028-08-30]},

      # Nordrhein-Westfalen
      {"nordrhein-westfalen", "herbst", ~D[2027-10-23], ~D[2027-11-06]},
      {"nordrhein-westfalen", "weihnachten", ~D[2027-12-24], ~D[2028-01-08]},
      {"nordrhein-westfalen", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"nordrhein-westfalen", "sommer", ~D[2028-07-10], ~D[2028-08-22]},

      # Rheinland-Pfalz
      {"rheinland-pfalz", "herbst", ~D[2027-10-04], ~D[2027-10-15]},
      {"rheinland-pfalz", "weihnachten", ~D[2027-12-23], ~D[2028-01-07]},
      {"rheinland-pfalz", "ostern", ~D[2028-04-10], ~D[2028-04-21]},
      {"rheinland-pfalz", "sommer", ~D[2028-07-03], ~D[2028-08-11]},

      # Saarland
      {"saarland", "herbst", ~D[2027-10-04], ~D[2027-10-15]},
      {"saarland", "weihnachten", ~D[2027-12-20], ~D[2027-12-31]},
      {"saarland", "winter", ~D[2028-02-21], ~D[2028-02-29]},
      {"saarland", "ostern", ~D[2028-04-12], ~D[2028-04-21]},
      {"saarland", "sommer", ~D[2028-07-03], ~D[2028-08-11]},

      # Sachsen
      {"sachsen", "herbst", ~D[2027-10-11], ~D[2027-10-23]},
      {"sachsen", "weihnachten", ~D[2027-12-23], ~D[2028-01-01]},
      {"sachsen", "winter", ~D[2028-02-14], ~D[2028-02-26]},
      {"sachsen", "ostern", ~D[2028-04-14], ~D[2028-04-22]},
      {"sachsen", "sommer", ~D[2028-07-22], ~D[2028-09-01]},

      # Sachsen-Anhalt
      {"sachsen-anhalt", "herbst", ~D[2027-10-18], ~D[2027-10-23]},
      {"sachsen-anhalt", "weihnachten", ~D[2027-12-20], ~D[2027-12-31]},
      {"sachsen-anhalt", "winter", ~D[2028-02-07], ~D[2028-02-12]},
      {"sachsen-anhalt", "ostern", ~D[2028-04-10], ~D[2028-04-22]},
      {"sachsen-anhalt", "himmelfahrt", ~D[2028-06-03], ~D[2028-06-10]},
      {"sachsen-anhalt", "sommer", ~D[2028-07-22], ~D[2028-09-01]},

      # Schleswig-Holstein
      {"schleswig-holstein", "herbst", ~D[2027-10-11], ~D[2027-10-23]},
      {"schleswig-holstein", "weihnachten", ~D[2027-12-23], ~D[2028-01-08]},
      {"schleswig-holstein", "ostern", ~D[2028-04-03], ~D[2028-04-15]},
      {"schleswig-holstein", "sommer", ~D[2028-06-24], ~D[2028-08-04]},

      # Thüringen
      {"thueringen", "herbst", ~D[2027-10-09], ~D[2027-10-23]},
      {"thueringen", "weihnachten", ~D[2027-12-23], ~D[2027-12-31]},
      {"thueringen", "winter", ~D[2028-02-07], ~D[2028-02-12]},
      {"thueringen", "ostern", ~D[2028-04-03], ~D[2028-04-15]},
      {"thueringen", "sommer", ~D[2028-07-22], ~D[2028-09-01]}
    ]

    # Insert vacation periods using Ecto
    Enum.each(vacation_data, fn {federal_state_slug, vacation_type_slug, starts_on, ends_on} ->
      # Find the location
      location =
        Repo.one(
          from(l in Location,
            where: l.slug == ^federal_state_slug and l.is_federal_state == true
          )
        )

      # Find the vacation type
      vacation_type =
        Repo.one(
          from(hvt in HolidayOrVacationType,
            where: hvt.slug == ^vacation_type_slug and hvt.default_is_school_vacation == true
          )
        )

      if location && vacation_type do
        # Check if period already exists
        existing_period =
          Repo.one(
            from(p in Period,
              where:
                p.location_id == ^location.id and
                  p.holiday_or_vacation_type_id == ^vacation_type.id and
                  p.starts_on == ^starts_on and
                  p.ends_on == ^ends_on
            )
          )

        unless existing_period do
          %Period{
            starts_on: starts_on,
            ends_on: ends_on,
            location_id: location.id,
            holiday_or_vacation_type_id: vacation_type.id,
            is_school_vacation: true,
            is_valid_for_students: true,
            is_valid_for_everybody: false,
            is_public_holiday: false,
            is_listed_below_month: true,
            display_priority: 5,
            html_class: "success",
            created_by_email_address: "claude@anthropic.com"
          }
          |> Repo.insert!()
        end
      end
    end)

    # Add single-day vacation periods and special holidays
    single_day_data = [
      # Hamburg winter single day
      {"hamburg", "winter", ~D[2028-01-28]},

      # Baden-Württemberg individual Easter day
      {"baden-wuerttemberg", "christi-himmelfahrt", ~D[2028-04-13]},

      # Berlin Himmelfahrt/Pfingsten individual days
      {"berlin", "christi-himmelfahrt", ~D[2028-05-26]},
      {"berlin", "pfingstmontag", ~D[2028-06-01]},
      {"berlin", "pfingstmontag", ~D[2028-06-02]},

      # Bremen individual days
      {"bremen", "christi-himmelfahrt", ~D[2028-05-26]},
      {"bremen", "pfingstmontag", ~D[2028-06-06]},

      # Mecklenburg-Vorpommern individual days
      {"mecklenburg-vorpommern", "winter", ~D[2028-02-18]},
      {"mecklenburg-vorpommern", "christi-himmelfahrt", ~D[2028-05-26]},

      # Niedersachsen individual days
      {"niedersachsen", "christi-himmelfahrt", ~D[2028-05-26]},
      {"niedersachsen", "pfingstmontag", ~D[2028-06-06]},

      # Sachsen individual day
      {"sachsen", "christi-himmelfahrt", ~D[2028-05-26]},

      # Schleswig-Holstein individual day
      {"schleswig-holstein", "christi-himmelfahrt", ~D[2028-05-26]},

      # Thüringen individual day
      {"thueringen", "christi-himmelfahrt", ~D[2028-05-26]}
    ]

    # Insert single-day periods using Ecto
    Enum.each(single_day_data, fn {federal_state_slug, vacation_type_slug, date} ->
      # Find the location
      location =
        Repo.one(
          from(l in Location,
            where: l.slug == ^federal_state_slug and l.is_federal_state == true
          )
        )

      # Find the vacation type (don't require default_is_school_vacation for holidays)
      vacation_type =
        Repo.one(
          from(hvt in HolidayOrVacationType,
            where: hvt.slug == ^vacation_type_slug
          )
        )

      if location && vacation_type do
        # Check if period already exists
        existing_period =
          Repo.one(
            from(p in Period,
              where:
                p.location_id == ^location.id and
                  p.holiday_or_vacation_type_id == ^vacation_type.id and
                  p.starts_on == ^date and
                  p.ends_on == ^date
            )
          )

        unless existing_period do
          %Period{
            starts_on: date,
            ends_on: date,
            location_id: location.id,
            holiday_or_vacation_type_id: vacation_type.id,
            is_school_vacation: false,
            is_valid_for_students: false,
            is_valid_for_everybody: true,
            is_public_holiday: true,
            is_listed_below_month: true,
            display_priority: 10,
            html_class: "warning",
            created_by_email_address: "claude@anthropic.com"
          }
          |> Repo.insert!()
        end
      end
    end)

    # Add bewegliche Ferientage (movable vacation days) for each federal state
    # These are flexible vacation days that schools can assign throughout the year
    bewegliche_ferientage_data = [
      # Baden-Württemberg: 4 bewegliche Ferientage
      {"baden-wuerttemberg", 4},
      # Bayern: 0 bewegliche Ferientage
      {"bayern", 0},
      # Berlin: 0 bewegliche Ferientage
      {"berlin", 0},
      # Brandenburg: 1 beweglicher Ferientag
      {"brandenburg", 1},
      # Bremen: 1 beweglicher Ferientag
      {"bremen", 1},
      # Hamburg: 0 bewegliche Ferientage
      {"hamburg", 0},
      # Hessen: 3 bewegliche Ferientage (NOTE: Changed from 4 to 3 for 2027/2028)
      {"hessen", 3},
      # Mecklenburg-Vorpommern: 0 bewegliche Ferientage
      {"mecklenburg-vorpommern", 0},
      # Niedersachsen: 0 bewegliche Ferientage
      {"niedersachsen", 0},
      # Nordrhein-Westfalen: 3 bewegliche Ferientage
      {"nordrhein-westfalen", 3},
      # Rheinland-Pfalz: 6 bewegliche Ferientage
      {"rheinland-pfalz", 6},
      # Saarland: 1 beweglicher Ferientag (NOTE: Changed from 2 to 1 for 2027/2028)
      {"saarland", 1},
      # Sachsen: 1 beweglicher Ferientag
      {"sachsen", 1},
      # Sachsen-Anhalt: 1 beweglicher Ferientag (NOTE: Changed from 2 to 1 for 2027/2028)
      {"sachsen-anhalt", 1},
      # Schleswig-Holstein: 1 beweglicher Ferientag
      {"schleswig-holstein", 1},
      # Thüringen: 1 beweglicher Ferientag
      {"thueringen", 1}
    ]

    # Insert bewegliche Ferientage using Ecto
    # Note: These are placeholder periods representing the available quota for each state
    Enum.each(bewegliche_ferientage_data, fn {federal_state_slug, count} ->
      if count > 0 do
        # Find the location
        location =
          Repo.one(
            from(l in Location,
              where: l.slug == ^federal_state_slug and l.is_federal_state == true
            )
          )

        # Find the beweglicher-ferientag vacation type
        vacation_type =
          Repo.one(
            from(hvt in HolidayOrVacationType,
              where: hvt.slug == "beweglicher-ferientag"
            )
          )

        if location && vacation_type do
          # Create placeholder periods for each beweglicher Ferientag
          Enum.each(1..count, fn index ->
            # Use different placeholder dates to avoid unique constraint violation
            placeholder_date = Date.add(~D[2027-09-01], index - 1)

            memo =
              "Beweglicher Ferientag #{index} für Schuljahr 2027/2028 - Datum wird von der Schule festgelegt"

            # Check if period already exists
            existing_period =
              Repo.one(
                from(p in Period,
                  where:
                    p.location_id == ^location.id and
                      p.holiday_or_vacation_type_id == ^vacation_type.id and
                      p.memo == ^memo
                )
              )

            unless existing_period do
              %Period{
                starts_on: placeholder_date,
                ends_on: placeholder_date,
                location_id: location.id,
                holiday_or_vacation_type_id: vacation_type.id,
                is_school_vacation: true,
                is_valid_for_students: true,
                is_valid_for_everybody: false,
                is_public_holiday: false,
                is_listed_below_month: true,
                display_priority: 7,
                html_class: "success",
                created_by_email_address: "claude@anthropic.com",
                memo: memo
              }
              |> Repo.insert!()
            end
          end)
        end
      end
    end)
  end

  def down do
    # Remove the vacation periods added by this migration using Ecto
    from(p in Period,
      where:
        p.created_by_email_address == "claude@anthropic.com" and
          ((p.starts_on >= ^~D[2027-10-01] and p.starts_on <= ^~D[2028-09-30]) or
             (p.ends_on >= ^~D[2027-10-01] and p.ends_on <= ^~D[2028-09-30]))
    )
    |> Repo.delete_all()
  end
end
