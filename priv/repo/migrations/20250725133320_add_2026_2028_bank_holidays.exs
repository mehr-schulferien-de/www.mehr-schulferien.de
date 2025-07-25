defmodule MehrSchulferien.Repo.Migrations.Add20262028BankHolidays do
  use Ecto.Migration

  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def up do
    # First, ensure we have the missing holiday type for "75. Jahrestag Volksaufstand 17. Juni"
    jahrestag_type =
      Repo.one(
        from(hvt in HolidayOrVacationType,
          where: hvt.slug == "75-jahrestag-volksaufstand-17-juni"
        )
      )

    unless jahrestag_type do
      %HolidayOrVacationType{
        name: "75. Jahrestag Volksaufstand 17. Juni",
        colloquial: "75. Jahrestag Volksaufstand 17. Juni",
        slug: "75-jahrestag-volksaufstand-17-juni",
        # Deutschland
        country_location_id: 1,
        default_html_class: "info",
        default_is_listed_below_month: false,
        default_display_priority: 10,
        default_is_public_holiday: true,
        default_is_school_vacation: false,
        default_is_valid_for_everybody: true,
        default_is_valid_for_students: true
      }
      |> Repo.insert!()
    end

    # Define bank holiday data structure
    # Format: {year, holiday_slug, date, locations, options}
    # locations can be :all or a list of federal state slugs
    # options: %{valid_for: :all | :students, city: "city_name", plz: "zip_code"}
    bank_holidays = [
      # 2026 - Bundesweite Feiertage
      {2026, "neujahrstag", ~D[2026-01-01], :all, %{valid_for: :all}},
      {2026, "karfreitag", ~D[2026-04-03], :all, %{valid_for: :all}},
      {2026, "ostermontag", ~D[2026-04-06], :all, %{valid_for: :all}},
      {2026, "tag-der-arbeit", ~D[2026-05-01], :all, %{valid_for: :all}},
      {2026, "christi-himmelfahrt", ~D[2026-05-14], :all, %{valid_for: :all}},
      {2026, "pfingstmontag", ~D[2026-05-25], :all, %{valid_for: :all}},
      {2026, "tag-der-deutschen-einheit", ~D[2026-10-03], :all, %{valid_for: :all}},
      {2026, "1-weihnachtstag", ~D[2026-12-25], :all, %{valid_for: :all}},
      {2026, "2-weihnachtstag", ~D[2026-12-26], :all, %{valid_for: :all}},

      # 2026 - Regionale Feiertage
      {2026, "heilige-drei-koenige", ~D[2026-01-06],
       ["baden-wuerttemberg", "bayern", "sachsen-anhalt"], %{valid_for: :all}},
      {2026, "fronleichnam", ~D[2026-06-04],
       [
         "baden-wuerttemberg",
         "bayern",
         "hessen",
         "nordrhein-westfalen",
         "rheinland-pfalz",
         "saarland"
       ], %{valid_for: :all}},
      {2026, "augsburger-hohes-friedensfest", ~D[2026-08-08], ["bayern"],
       %{valid_for: :all, city: "Augsburg"}},
      {2026, "mariae-himmelfahrt", ~D[2026-08-15], ["saarland"], %{valid_for: :all}},
      {2026, "weltkindertag", ~D[2026-09-20], ["thueringen"], %{valid_for: :students}},
      {2026, "buss-und-bettag", ~D[2026-11-18], ["sachsen"], %{valid_for: :all}},
      {2026, "frauentag", ~D[2026-03-08], ["berlin", "mecklenburg-vorpommern"],
       %{valid_for: :all}},
      {2026, "ostersonntag", ~D[2026-04-05], ["brandenburg"], %{valid_for: :all}},
      {2026, "pfingstsonntag", ~D[2026-05-24], ["brandenburg"], %{valid_for: :all}},

      # 2027 - Bundesweite Feiertage
      {2027, "neujahrstag", ~D[2027-01-01], :all, %{valid_for: :all}},
      {2027, "karfreitag", ~D[2027-03-26], :all, %{valid_for: :all}},
      {2027, "ostermontag", ~D[2027-03-29], :all, %{valid_for: :all}},
      {2027, "tag-der-arbeit", ~D[2027-05-01], :all, %{valid_for: :all}},
      {2027, "christi-himmelfahrt", ~D[2027-05-06], :all, %{valid_for: :all}},
      {2027, "pfingstmontag", ~D[2027-05-17], :all, %{valid_for: :all}},
      {2027, "tag-der-deutschen-einheit", ~D[2027-10-03], :all, %{valid_for: :all}},
      {2027, "1-weihnachtstag", ~D[2027-12-25], :all, %{valid_for: :all}},
      {2027, "2-weihnachtstag", ~D[2027-12-26], :all, %{valid_for: :all}},

      # 2027 - Regionale Feiertage
      {2027, "heilige-drei-koenige", ~D[2027-01-06],
       ["baden-wuerttemberg", "bayern", "sachsen-anhalt"], %{valid_for: :all}},
      {2027, "fronleichnam", ~D[2027-05-27],
       [
         "baden-wuerttemberg",
         "bayern",
         "hessen",
         "nordrhein-westfalen",
         "rheinland-pfalz",
         "saarland"
       ], %{valid_for: :all}},
      {2027, "augsburger-hohes-friedensfest", ~D[2027-08-08], ["bayern"],
       %{valid_for: :all, city: "Augsburg"}},
      {2027, "mariae-himmelfahrt", ~D[2027-08-15], ["saarland"], %{valid_for: :all}},
      {2027, "buss-und-bettag", ~D[2027-11-17], ["sachsen"], %{valid_for: :all}},
      {2027, "frauentag", ~D[2027-03-08], ["berlin", "mecklenburg-vorpommern"],
       %{valid_for: :all}},
      {2027, "ostersonntag", ~D[2027-03-28], ["brandenburg"], %{valid_for: :all}},
      {2027, "pfingstsonntag", ~D[2027-05-16], ["brandenburg"], %{valid_for: :all}},

      # 2028 - Bundesweite Feiertage
      {2028, "neujahrstag", ~D[2028-01-01], :all, %{valid_for: :all}},
      {2028, "karfreitag", ~D[2028-04-14], :all, %{valid_for: :all}},
      {2028, "ostermontag", ~D[2028-04-17], :all, %{valid_for: :all}},
      {2028, "tag-der-arbeit", ~D[2028-05-01], :all, %{valid_for: :all}},
      {2028, "christi-himmelfahrt", ~D[2028-05-25], :all, %{valid_for: :all}},
      {2028, "pfingstmontag", ~D[2028-06-05], :all, %{valid_for: :all}},
      {2028, "tag-der-deutschen-einheit", ~D[2028-10-03], :all, %{valid_for: :all}},
      {2028, "1-weihnachtstag", ~D[2028-12-25], :all, %{valid_for: :all}},
      {2028, "2-weihnachtstag", ~D[2028-12-26], :all, %{valid_for: :all}},

      # 2028 - Regionale Feiertage
      {2028, "heilige-drei-koenige", ~D[2028-01-06],
       ["baden-wuerttemberg", "bayern", "sachsen-anhalt"], %{valid_for: :all}},
      {2028, "fronleichnam", ~D[2028-06-15],
       [
         "baden-wuerttemberg",
         "bayern",
         "hessen",
         "nordrhein-westfalen",
         "rheinland-pfalz",
         "saarland"
       ], %{valid_for: :all}},
      {2028, "augsburger-hohes-friedensfest", ~D[2028-08-08], ["bayern"],
       %{valid_for: :all, city: "Augsburg"}},
      {2028, "mariae-himmelfahrt", ~D[2028-08-15], ["saarland"], %{valid_for: :all}},
      {2028, "buss-und-bettag", ~D[2028-11-22], ["sachsen"], %{valid_for: :all}},
      {2028, "frauentag", ~D[2028-03-08], ["berlin", "mecklenburg-vorpommern"],
       %{valid_for: :all}},
      {2028, "75-jahrestag-volksaufstand-17-juni", ~D[2028-06-17], ["berlin"],
       %{valid_for: :all}},
      {2028, "ostersonntag", ~D[2028-04-16], ["brandenburg"], %{valid_for: :all}},
      {2028, "pfingstsonntag", ~D[2028-06-04], ["brandenburg"], %{valid_for: :all}}
    ]

    # Get all federal states for nationwide holidays
    all_federal_states = Repo.all(from(l in Location, where: l.is_federal_state == true))

    # Process each bank holiday
    Enum.each(bank_holidays, fn {_year, holiday_slug, date, location_spec, options} ->
      # Get holiday type
      holiday_type =
        Repo.one!(from(hvt in HolidayOrVacationType, where: hvt.slug == ^holiday_slug))

      # Determine locations
      locations =
        case location_spec do
          :all ->
            all_federal_states

          state_slugs ->
            Repo.all(
              from(l in Location,
                where: l.slug in ^state_slugs and l.is_federal_state == true
              )
            )
        end

      # Insert period for each location
      Enum.each(locations, fn location ->
        # For special cases like Augsburg, find the city and use it instead
        final_location =
          if options[:city] do
            case options[:city] do
              "Augsburg" ->
                Repo.one(
                  from(l in Location,
                    where: l.is_city == true and l.name == "Augsburg",
                    limit: 1
                  )
                ) || location

              _ ->
                location
            end
          else
            location
          end

        # Check if period already exists
        existing_period =
          Repo.one(
            from(p in Period,
              where:
                p.location_id == ^final_location.id and
                  p.holiday_or_vacation_type_id == ^holiday_type.id and
                  p.starts_on == ^date and
                  p.ends_on == ^date
            )
          )

        unless existing_period do
          %Period{
            starts_on: date,
            ends_on: date,
            location_id: final_location.id,
            holiday_or_vacation_type_id: holiday_type.id,
            is_public_holiday: true,
            is_school_vacation: false,
            is_valid_for_everybody: options[:valid_for] == :all,
            is_valid_for_students: true,
            is_listed_below_month: false,
            display_priority: 10,
            html_class: "info",
            created_by_email_address: "claude@anthropic.com"
          }
          |> Repo.insert!()
        end
      end)
    end)
  end

  def down do
    # Remove all bank holidays added by this migration for 2026-2028
    dates = [
      # 2026
      ~D[2026-01-01],
      ~D[2026-01-06],
      ~D[2026-03-08],
      ~D[2026-04-03],
      ~D[2026-04-05],
      ~D[2026-04-06],
      ~D[2026-05-01],
      ~D[2026-05-14],
      ~D[2026-05-24],
      ~D[2026-05-25],
      ~D[2026-06-04],
      ~D[2026-08-08],
      ~D[2026-08-15],
      ~D[2026-09-20],
      ~D[2026-10-03],
      ~D[2026-11-18],
      ~D[2026-12-25],
      ~D[2026-12-26],
      # 2027
      ~D[2027-01-01],
      ~D[2027-01-06],
      ~D[2027-03-08],
      ~D[2027-03-26],
      ~D[2027-03-28],
      ~D[2027-03-29],
      ~D[2027-05-01],
      ~D[2027-05-06],
      ~D[2027-05-16],
      ~D[2027-05-17],
      ~D[2027-05-27],
      ~D[2027-08-08],
      ~D[2027-08-15],
      ~D[2027-10-03],
      ~D[2027-11-17],
      ~D[2027-12-25],
      ~D[2027-12-26],
      # 2028
      ~D[2028-01-01],
      ~D[2028-01-06],
      ~D[2028-03-08],
      ~D[2028-04-14],
      ~D[2028-04-16],
      ~D[2028-04-17],
      ~D[2028-05-01],
      ~D[2028-05-25],
      ~D[2028-06-04],
      ~D[2028-06-05],
      ~D[2028-06-15],
      ~D[2028-06-17],
      ~D[2028-08-08],
      ~D[2028-08-15],
      ~D[2028-10-03],
      ~D[2028-11-22],
      ~D[2028-12-25],
      ~D[2028-12-26]
    ]

    Repo.delete_all(
      from(p in Period,
        where:
          p.starts_on in ^dates and
            p.ends_on in ^dates and
            p.is_public_holiday == true and
            p.created_by_email_address == "claude@anthropic.com"
      )
    )

    # Also remove the holiday type if we created it
    Repo.delete_all(
      from(hvt in HolidayOrVacationType,
        where: hvt.slug == "75-jahrestag-volksaufstand-17-juni"
      )
    )
  end
end
