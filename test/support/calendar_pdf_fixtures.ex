defmodule MehrSchulferien.CalendarPdfFixtures do
  @moduledoc """
  Locations and periods for the calendar PDF tests: one federal state with
  vacations and a public holiday in 2027, and one school with an address and a
  beweglicher Ferientag.
  """

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Repo

  def calendar_fixture do
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{name: "Hessen", slug: "hessen", parent_location_id: country.id})

    county = insert(:county, %{parent_location_id: federal_state.id})
    city = insert(:city, %{name: "Kassel", slug: "kassel", parent_location_id: county.id})

    school =
      insert(:school, %{
        name: "Goethe-Gymnasium & Co_1",
        slug: "34117-goethe-gymnasium",
        parent_location_id: city.id
      })

    Repo.insert!(%Address{
      school_location_id: school.id,
      street: "Ysenburgstraße 41",
      zip_code: "34117",
      city: "Kassel",
      homepage_url: "https://www.goethe-gymnasium-kassel.de/"
    })

    sommer =
      insert(:holiday_or_vacation_type, %{name: "Sommer", country_location_id: country.id})

    herbst =
      insert(:holiday_or_vacation_type, %{name: "Herbst", country_location_id: country.id})

    feiertag =
      insert(:holiday_or_vacation_type, %{
        name: "Tag der Deutschen Einheit",
        colloquial: nil,
        default_is_school_vacation: false,
        default_is_public_holiday: true,
        country_location_id: country.id
      })

    beweglich =
      insert(:holiday_or_vacation_type, %{
        name: "Beweglicher Ferientag",
        colloquial: "Beweglicher Ferientag",
        slug: "beweglicher-ferientag",
        default_is_school_vacation: false,
        country_location_id: country.id
      })

    vacation(federal_state, sommer, ~D[2027-06-28], ~D[2027-08-06])
    vacation(federal_state, herbst, ~D[2027-10-04], ~D[2027-10-16])

    insert(:period, %{
      location_id: country.id,
      holiday_or_vacation_type_id: feiertag.id,
      starts_on: ~D[2027-10-03],
      ends_on: ~D[2027-10-03],
      is_public_holiday: true,
      is_valid_for_everybody: true
    })

    insert(:period, %{
      location_id: school.id,
      holiday_or_vacation_type_id: beweglich.id,
      starts_on: ~D[2027-05-07],
      ends_on: ~D[2027-05-07],
      is_valid_for_students: true
    })

    %{
      country: country,
      federal_state: federal_state,
      county: county,
      city: city,
      school: MehrSchulferien.Locations.get_school_by_slug!(school.slug),
      vacation_type: sommer
    }
  end

  def vacation(location, type, starts_on, ends_on) do
    insert(:period, %{
      location_id: location.id,
      holiday_or_vacation_type_id: type.id,
      starts_on: starts_on,
      ends_on: ends_on,
      is_school_vacation: true,
      is_valid_for_students: true
    })
  end

  @doc "Empties the PDF store and resets the stub compiler."
  def reset_calendar_pdfs do
    File.rm_rf!(MehrSchulferien.CalendarPdf.Store.dir())
    Application.delete_env(:mehr_schulferien, :calendar_pdf_stub_listener)
    Application.delete_env(:mehr_schulferien, :calendar_pdf_stub_delay)
    Application.delete_env(:mehr_schulferien, :calendar_pdf_stub_result)
    Application.delete_env(:mehr_schulferien, :calendar_pdf_max_queue)
    :ok
  end
end
