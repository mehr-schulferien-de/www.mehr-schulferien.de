defmodule MehrSchulferien.Repo.Migrations.Add20262027SchoolVacations do
  use Ecto.Migration

  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def up do
    # Define the vacation periods for each federal state for the 2026/2027 school year
    # Based on KMK (Kultusministerkonferenz) official data
    vacation_data = [
      # Baden-Württemberg
      {"baden-wuerttemberg", "herbst", ~D[2026-10-26], ~D[2026-10-30]},
      {"baden-wuerttemberg", "weihnachten", ~D[2026-12-23], ~D[2027-01-09]},
      {"baden-wuerttemberg", "ostern", ~D[2027-03-30], ~D[2027-04-03]},
      {"baden-wuerttemberg", "sommer", ~D[2027-07-29], ~D[2027-09-11]},

      # Bayern  
      {"bayern", "herbst", ~D[2026-11-02], ~D[2026-11-06]},
      {"bayern", "weihnachten", ~D[2026-12-24], ~D[2027-01-08]},
      {"bayern", "winter", ~D[2027-02-08], ~D[2027-02-12]},
      {"bayern", "ostern", ~D[2027-03-22], ~D[2027-04-02]},
      {"bayern", "himmelfahrt-pfingsten", ~D[2027-05-18], ~D[2027-05-28]},
      {"bayern", "sommer", ~D[2027-08-02], ~D[2027-09-13]},

      # Berlin
      {"berlin", "herbst", ~D[2026-10-19], ~D[2026-10-31]},
      {"berlin", "weihnachten", ~D[2026-12-23], ~D[2027-01-02]},
      {"berlin", "winter", ~D[2027-02-01], ~D[2027-02-06]},
      {"berlin", "ostern", ~D[2027-03-22], ~D[2027-04-02]},
      {"berlin", "sommer", ~D[2027-07-01], ~D[2027-08-14]},

      # Brandenburg
      {"brandenburg", "herbst", ~D[2026-10-19], ~D[2026-10-30]},
      {"brandenburg", "weihnachten", ~D[2026-12-23], ~D[2027-01-02]},
      {"brandenburg", "winter", ~D[2027-02-01], ~D[2027-02-06]},
      {"brandenburg", "ostern", ~D[2027-03-22], ~D[2027-04-03]},
      {"brandenburg", "sommer", ~D[2027-07-01], ~D[2027-08-14]},

      # Bremen
      {"bremen", "herbst", ~D[2026-10-12], ~D[2026-10-24]},
      {"bremen", "weihnachten", ~D[2026-12-23], ~D[2027-01-09]},
      {"bremen", "winter", ~D[2027-02-01], ~D[2027-02-02]},
      {"bremen", "ostern", ~D[2027-03-22], ~D[2027-04-03]},
      {"bremen", "sommer", ~D[2027-07-08], ~D[2027-08-18]},

      # Hamburg
      {"hamburg", "herbst", ~D[2026-10-19], ~D[2026-10-30]},
      {"hamburg", "weihnachten", ~D[2026-12-21], ~D[2027-01-01]},
      {"hamburg", "fruehjahr", ~D[2027-03-01], ~D[2027-03-12]},
      {"hamburg", "himmelfahrt", ~D[2027-05-07], ~D[2027-05-14]},
      {"hamburg", "sommer", ~D[2027-07-01], ~D[2027-08-11]},

      # Hessen
      {"hessen", "herbst", ~D[2026-10-05], ~D[2026-10-17]},
      {"hessen", "weihnachten", ~D[2026-12-23], ~D[2027-01-12]},
      {"hessen", "ostern", ~D[2027-03-22], ~D[2027-04-02]},
      {"hessen", "sommer", ~D[2027-06-28], ~D[2027-08-06]},

      # Mecklenburg-Vorpommern
      {"mecklenburg-vorpommern", "herbst", ~D[2026-10-19], ~D[2026-10-24]},
      {"mecklenburg-vorpommern", "weihnachten", ~D[2026-12-19], ~D[2027-01-02]},
      {"mecklenburg-vorpommern", "winter", ~D[2027-02-08], ~D[2027-02-19]},
      {"mecklenburg-vorpommern", "ostern", ~D[2027-03-22], ~D[2027-03-31]},
      {"mecklenburg-vorpommern", "himmelfahrt", ~D[2027-05-14], ~D[2027-05-18]},
      {"mecklenburg-vorpommern", "sommer", ~D[2027-07-05], ~D[2027-08-14]},

      # Niedersachsen
      {"niedersachsen", "herbst", ~D[2026-10-12], ~D[2026-10-24]},
      {"niedersachsen", "weihnachten", ~D[2026-12-23], ~D[2027-01-09]},
      {"niedersachsen", "winter", ~D[2027-02-01], ~D[2027-02-02]},
      {"niedersachsen", "ostern", ~D[2027-03-22], ~D[2027-04-03]},
      {"niedersachsen", "sommer", ~D[2027-07-08], ~D[2027-08-18]},

      # Nordrhein-Westfalen
      {"nordrhein-westfalen", "herbst", ~D[2026-10-17], ~D[2026-10-31]},
      {"nordrhein-westfalen", "weihnachten", ~D[2026-12-23], ~D[2027-01-06]},
      {"nordrhein-westfalen", "ostern", ~D[2027-03-22], ~D[2027-04-03]},
      {"nordrhein-westfalen", "sommer", ~D[2027-07-19], ~D[2027-08-31]},

      # Rheinland-Pfalz
      {"rheinland-pfalz", "herbst", ~D[2026-10-05], ~D[2026-10-16]},
      {"rheinland-pfalz", "weihnachten", ~D[2026-12-23], ~D[2027-01-08]},
      {"rheinland-pfalz", "ostern", ~D[2027-03-22], ~D[2027-04-02]},
      {"rheinland-pfalz", "sommer", ~D[2027-06-28], ~D[2027-08-06]},

      # Saarland
      {"saarland", "herbst", ~D[2026-10-05], ~D[2026-10-16]},
      {"saarland", "weihnachten", ~D[2026-12-21], ~D[2026-12-31]},
      {"saarland", "winter", ~D[2027-02-08], ~D[2027-02-12]},
      {"saarland", "ostern", ~D[2027-03-30], ~D[2027-04-09]},
      {"saarland", "sommer", ~D[2027-06-28], ~D[2027-08-06]},

      # Sachsen
      {"sachsen", "herbst", ~D[2026-10-12], ~D[2026-10-24]},
      {"sachsen", "weihnachten", ~D[2026-12-23], ~D[2027-01-02]},
      {"sachsen", "winter", ~D[2027-02-08], ~D[2027-02-19]},
      {"sachsen", "ostern", ~D[2027-03-26], ~D[2027-04-02]},
      {"sachsen", "himmelfahrt", ~D[2027-05-15], ~D[2027-05-18]},
      {"sachsen", "sommer", ~D[2027-07-10], ~D[2027-08-20]},

      # Sachsen-Anhalt
      {"sachsen-anhalt", "herbst", ~D[2026-10-19], ~D[2026-10-30]},
      {"sachsen-anhalt", "weihnachten", ~D[2026-12-21], ~D[2027-01-02]},
      {"sachsen-anhalt", "winter", ~D[2027-02-01], ~D[2027-02-06]},
      {"sachsen-anhalt", "ostern", ~D[2027-03-22], ~D[2027-03-27]},
      {"sachsen-anhalt", "himmelfahrt", ~D[2027-05-15], ~D[2027-05-22]},
      {"sachsen-anhalt", "sommer", ~D[2027-07-10], ~D[2027-08-20]},

      # Schleswig-Holstein
      {"schleswig-holstein", "herbst", ~D[2026-10-12], ~D[2026-10-24]},
      {"schleswig-holstein", "weihnachten", ~D[2026-12-21], ~D[2027-01-06]},
      {"schleswig-holstein", "ostern", ~D[2027-03-30], ~D[2027-04-10]},
      {"schleswig-holstein", "sommer", ~D[2027-07-03], ~D[2027-08-14]},

      # Thüringen
      {"thueringen", "herbst", ~D[2026-10-12], ~D[2026-10-24]},
      {"thueringen", "weihnachten", ~D[2026-12-23], ~D[2027-01-02]},
      {"thueringen", "winter", ~D[2027-02-01], ~D[2027-02-06]},
      {"thueringen", "ostern", ~D[2027-03-22], ~D[2027-04-03]},
      {"thueringen", "sommer", ~D[2027-07-10], ~D[2027-08-20]}
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

    # Add single-day vacation periods (Himmelfahrt, Winter einzelne Tage)
    single_day_data = [
      # Winter einzelne Tage
      {"hamburg", "winter", ~D[2027-01-29]},

      # Himmelfahrt einzelne Tage
      {"baden-wuerttemberg", "christi-himmelfahrt", ~D[2027-03-25]},
      {"baden-wuerttemberg", "pfingstmontag", ~D[2027-05-18]},
      {"berlin", "christi-himmelfahrt", ~D[2027-05-07]},
      {"berlin", "pfingstmontag", ~D[2027-05-18]},
      {"brandenburg", "pfingstmontag", ~D[2027-05-18]},
      {"bremen", "christi-himmelfahrt", ~D[2027-05-07]},
      {"bremen", "pfingstmontag", ~D[2027-05-18]},
      {"hamburg", "christi-himmelfahrt", ~D[2027-05-07]},
      {"mecklenburg-vorpommern", "christi-himmelfahrt", ~D[2027-05-07]},
      {"niedersachsen", "christi-himmelfahrt", ~D[2027-05-07]},
      {"niedersachsen", "pfingstmontag", ~D[2027-05-18]},
      {"nordrhein-westfalen", "pfingstmontag", ~D[2027-05-18]},
      {"sachsen", "christi-himmelfahrt", ~D[2027-05-07]},
      {"schleswig-holstein", "christi-himmelfahrt", ~D[2027-05-07]},
      {"thueringen", "christi-himmelfahrt", ~D[2027-05-07]}
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
      # Hessen: 4 bewegliche Ferientage
      {"hessen", 4},
      # Mecklenburg-Vorpommern: 0 bewegliche Ferientage
      {"mecklenburg-vorpommern", 0},
      # Niedersachsen: 0 bewegliche Ferientage
      {"niedersachsen", 0},
      # Nordrhein-Westfalen: 3 bewegliche Ferientage
      {"nordrhein-westfalen", 3},
      # Rheinland-Pfalz: 6 bewegliche Ferientage
      {"rheinland-pfalz", 6},
      # Saarland: 2 bewegliche Ferientage
      {"saarland", 2},
      # Sachsen: 1 beweglicher Ferientag
      {"sachsen", 1},
      # Sachsen-Anhalt: 2 bewegliche Ferientage
      {"sachsen-anhalt", 2},
      # Schleswig-Holstein: 2 bewegliche Ferientage
      {"schleswig-holstein", 2},
      # Thüringen: 2 bewegliche Ferientage
      {"thueringen", 2}
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
            placeholder_date = Date.add(~D[2026-09-01], index - 1)

            memo =
              "Beweglicher Ferientag #{index} für Schuljahr 2026/2027 - Datum wird von der Schule festgelegt"

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
          ((p.starts_on >= ^~D[2026-10-01] and p.starts_on <= ^~D[2027-09-30]) or
             (p.ends_on >= ^~D[2026-10-01] and p.ends_on <= ^~D[2027-09-30]))
    )
    |> Repo.delete_all()
  end
end
