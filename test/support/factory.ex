defmodule MehrSchulferien.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: MehrSchulferien.Repo

  alias MehrSchulferien.Calendars.{DateHelpers, HolidayOrVacationType, Religion}
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.{Address, ZipCode, ZipCodeMapping}
  alias MehrSchulferien.Blacklist.{VerificationRequest, Entry, RemovalLog}

  def address_factory(attrs) do
    school_id = attrs[:school_location_id] || insert(:school).id

    address = %Address{
      line1: "Schubart-Gymnasium Partnerschule für Europa",
      street: "Rombacher Straße 30",
      school_type: "Gymnasium",
      school_location_id: school_id
    }

    merge_attributes(address, attrs)
  end

  def holiday_or_vacation_type_factory(attrs) do
    name = attrs[:name] || Enum.random(["Herbst", "Sommer", "Weihnachts"])
    country_id = attrs[:country_location_id] || insert(:country).id

    # Check if name already has "ferien" suffix
    colloquial = if String.ends_with?(name, "ferien"), do: name, else: "#{name}ferien"

    # Generate unique slug if not provided
    slug = attrs[:slug] || sequence("#{String.downcase(name)}-vacation")

    holiday_or_vacation_type = %HolidayOrVacationType{
      name: name,
      colloquial: colloquial,
      default_display_priority: 3,
      default_is_listed_below_month: true,
      default_is_school_vacation: true,
      default_is_valid_for_students: true,
      slug: slug,
      wikipedia_url: "https://de.wikipedia.org/wiki/Schulferien##{name}ferien",
      country_location_id: country_id
    }

    merge_attributes(holiday_or_vacation_type, attrs)
  end

  def country_factory(attrs \\ %{}) do
    country = %Location{
      name: "Deutschland",
      code: "D",
      is_country: true,
      slug: sequence("deutschland")
    }

    merge_attributes(country, attrs)
  end

  def federal_state_factory(attrs) do
    country_id = attrs[:parent_location_id] || insert(:country).id

    federal_state = %Location{
      name: sequence("Berlin"),
      code: "BE",
      is_federal_state: true,
      parent_location_id: country_id,
      slug: sequence("berlin")
    }

    merge_attributes(federal_state, attrs)
  end

  def county_factory(attrs) do
    federal_state_id = attrs[:parent_location_id] || insert(:federal_state).id

    county = %Location{
      name: sequence("Koblenz"),
      code: "KO",
      is_county: true,
      parent_location_id: federal_state_id,
      slug: sequence("koblenz")
    }

    merge_attributes(county, attrs)
  end

  def city_factory(attrs) do
    county_id = attrs[:parent_location_id] || insert(:county).id

    city = %Location{
      name: sequence("Dresden"),
      code: "DR",
      is_city: true,
      parent_location_id: county_id,
      slug: sequence("dresden")
    }

    merge_attributes(city, attrs)
  end

  def school_factory(attrs) do
    city_id = attrs[:parent_location_id] || insert(:city).id

    school = %Location{
      name: sequence("Kopernikus-Gymnasium"),
      is_school: true,
      parent_location_id: city_id,
      slug: sequence("kopernikus-gymnasium")
    }

    merge_attributes(school, attrs)
  end

  def school_with_address_factory do
    # Build a school with an associated address
    school = build(:school)

    address = %MehrSchulferien.Maps.Address{
      street: "Teststraße 123",
      zip_code: "12345",
      city: "Teststadt",
      email_address: "test@school.de",
      phone_number: "+49 123 456789",
      homepage_url: "https://test-school.de",
      line1: "Schubart-Gymnasium Partnerschule für Europa",
      school_type: "Gymnasium"
    }

    # Return school with address
    %{school | address: address}
  end

  def period_factory(attrs \\ %{}) do
    federal_state = Map.get(attrs, :location_id) || insert(:federal_state).id

    period = %Period{
      created_by_email_address: "sw@wintermeyer-consulting.de",
      display_priority: 3,
      starts_on: Faker.Date.between(~D[2010-12-01], ~D[2015-12-01]),
      ends_on: Faker.Date.between(~D[2016-12-01], ~D[2019-12-01]),
      location_id: federal_state
    }

    # Only add the association if no ID is provided
    period =
      if Map.has_key?(attrs, :holiday_or_vacation_type_id) do
        period
      else
        Map.put(period, :holiday_or_vacation_type, build(:holiday_or_vacation_type))
      end

    merge_attributes(period, attrs)
  end

  def religion_factory do
    unique_suffix = System.unique_integer([:positive])
    name = "Test Religion #{unique_suffix}"

    %Religion{
      name: name,
      wikipedia_url: "https://de.wikipedia.org/wiki/Religion"
    }
  end

  def zip_code_factory do
    country = insert(:country)

    %ZipCode{
      value: Faker.format("#####"),
      country_location_id: country.id
    }
  end

  def zip_code_mapping_factory do
    location = insert(:city)
    zip_code = insert(:zip_code)

    %ZipCodeMapping{
      location_id: location.id,
      zip_code_id: zip_code.id,
      lat: 51.2,
      lon: 10.5
    }
  end

  def bridge_day_proposal_factory(attrs) do
    bridge_day = %MehrSchulferien.Periods.BridgeDayPeriod{
      starts_on: Date.new!(2026, 5, 1),
      ends_on: Date.new!(2026, 5, 4),
      number_days: 2,
      last_period_id: attrs[:last_period_id] || insert(:period).id
    }

    merge_attributes(bridge_day, attrs)
  end

  # Factory for creating holiday types commonly used in tests
  def holiday_type_factory(attrs) do
    name = attrs[:name] || "Feiertag"
    country_id = attrs[:country_location_id] || insert(:country).id

    # Generate unique slug if not provided
    slug = attrs[:slug] || sequence("#{String.downcase(name)}-holiday")

    holiday_type = %HolidayOrVacationType{
      name: name,
      colloquial: name,
      default_display_priority: 1,
      default_is_listed_below_month: false,
      default_is_school_vacation: false,
      default_is_valid_for_students: true,
      slug: slug,
      country_location_id: country_id
    }

    merge_attributes(holiday_type, attrs)
  end

  # Factory for creating weekend type
  def weekend_type_factory(attrs) do
    country_id = attrs[:country_location_id] || insert(:country).id

    # Generate unique slug if not provided
    slug = attrs[:slug] || sequence("wochenende")

    weekend_type = %HolidayOrVacationType{
      name: "Wochenende",
      colloquial: "Wochenende",
      default_display_priority: 3,
      default_is_listed_below_month: false,
      default_is_school_vacation: false,
      default_is_valid_for_students: false,
      slug: slug,
      country_location_id: country_id
    }

    merge_attributes(weekend_type, attrs)
  end

  # Factory for creating public holiday periods
  def public_holiday_factory(attrs) do
    location = attrs[:location_id] || insert(:federal_state).id
    holiday_type = attrs[:holiday_or_vacation_type] || build(:holiday_type)

    period = %Period{
      created_by_email_address: "test@example.com",
      display_priority: 1,
      starts_on: attrs[:starts_on] || Date.utc_today(),
      ends_on: attrs[:ends_on] || attrs[:starts_on] || Date.utc_today(),
      location_id: location,
      is_public_holiday: true,
      is_school_vacation: false
    }

    # Only add the association if no ID is provided
    period =
      if Map.has_key?(attrs, :holiday_or_vacation_type_id) do
        period
      else
        Map.put(period, :holiday_or_vacation_type, holiday_type)
      end

    merge_attributes(period, attrs)
  end

  # Factory for creating school vacation periods
  def school_vacation_factory(attrs) do
    location = attrs[:location_id] || insert(:federal_state).id
    vacation_type = attrs[:holiday_or_vacation_type] || build(:holiday_or_vacation_type)

    period = %Period{
      created_by_email_address: "test@example.com",
      display_priority: 3,
      starts_on: attrs[:starts_on] || Date.utc_today(),
      ends_on: attrs[:ends_on] || Date.add(Date.utc_today(), 7),
      location_id: location,
      is_public_holiday: false,
      is_school_vacation: true
    }

    # Only add the association if no ID is provided
    period =
      if Map.has_key?(attrs, :holiday_or_vacation_type_id) do
        period
      else
        Map.put(period, :holiday_or_vacation_type, vacation_type)
      end

    merge_attributes(period, attrs)
  end

  def add_school_periods(%{location: location}) do
    oster = insert(:holiday_or_vacation_type, %{name: "Oster"})
    herbst = insert(:holiday_or_vacation_type, %{name: "Herbst"})
    weihnachts = insert(:holiday_or_vacation_type, %{name: "Weihnachts"})
    winter = insert(:holiday_or_vacation_type, %{name: "Winter"})

    data = [
      {oster, ~D[2020-04-06], ~D[2020-04-18]},
      {herbst, ~D[2020-10-31], ~D[2020-10-31]},
      {weihnachts, ~D[2020-12-23], ~D[2021-01-04]},
      {winter, ~D[2021-02-24], ~D[2021-02-28]},
      {oster, ~D[2021-04-06], ~D[2021-04-18]},
      {herbst, ~D[2021-10-24], ~D[2021-10-27]},
      {herbst, ~D[2021-10-31], ~D[2021-10-31]},
      {weihnachts, ~D[2021-12-23], ~D[2022-01-04]},
      {oster, ~D[2022-04-06], ~D[2022-04-18]},
      {herbst, ~D[2022-10-31], ~D[2022-10-31]},
      {weihnachts, ~D[2022-12-23], ~D[2023-01-04]}
    ]

    for {vacation_type, starts_on, ends_on} <- data do
      create_period(%{
        created_by_email_address: "froderick@example.com",
        location_id: location.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: starts_on,
        ends_on: ends_on
      })
    end
  end

  def add_public_periods(%{location: location}) do
    today = DateHelpers.today_berlin()
    current_year = today.year
    future_year = current_year + 1

    # Create bridge days for current year
    create_bridge_day_periods(location.id, current_year)

    # Create bridge days for next year
    create_bridge_day_periods(location.id, future_year)
  end

  defp create_bridge_day_periods(location_id, year) do
    unique_suffix = System.unique_integer([:positive])

    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Test Holiday #{unique_suffix}",
        slug: "test-holiday-#{year}-#{unique_suffix}"
      })

    weekend_type =
      insert(:holiday_or_vacation_type, %{
        name: "Wochenende #{unique_suffix}",
        slug: "wochenende-#{year}-#{unique_suffix}"
      })

    # Create a bridge day scenario that meets minimum gain requirements:
    # 1 day off should result in at least 4 free days

    # Thursday holiday (May 1st)
    create_period(%{
      is_public_holiday: true,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(year, 5, 1),
      ends_on: Date.new!(year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Sunday holiday (May 4th)
    create_period(%{
      is_public_holiday: true,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(year, 5, 4),
      ends_on: Date.new!(year, 5, 4),
      display_priority: 2,
      created_by_email_address: "test@example.com"
    })

    # Weekend days (Saturday and Sunday)
    create_period(%{
      is_public_holiday: false,
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: Date.new!(year, 5, 3),
      ends_on: Date.new!(year, 5, 4),
      display_priority: 3,
      created_by_email_address: "test@example.com"
    })
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end

  # Helper function to create test periods for a specific year
  def create_test_periods(country_id, location_id, year \\ nil) do
    year = year || Date.utc_today().year

    # Create holiday types with unique names
    unique_suffix = System.unique_integer([:positive])

    holiday_type =
      insert(:holiday_type, %{
        name: "Test Holiday #{unique_suffix}",
        slug: "test-holiday-#{year}-#{unique_suffix}",
        country_location_id: country_id
      })

    weekend_type =
      insert(:weekend_type, %{
        name: "Wochenende #{unique_suffix}",
        slug: "wochenende-#{year}-#{unique_suffix}",
        country_location_id: country_id
      })

    # Create holidays for bridge day scenarios
    # Labor Day (May 1)
    insert(:public_holiday, %{
      holiday_or_vacation_type_id: holiday_type.id,
      location_id: location_id,
      starts_on: Date.new!(year, 5, 1),
      ends_on: Date.new!(year, 5, 1),
      display_priority: 1
    })

    # Weekend (May 3-4)
    insert(:period, %{
      holiday_or_vacation_type_id: weekend_type.id,
      location_id: location_id,
      starts_on: Date.new!(year, 5, 3),
      ends_on: Date.new!(year, 5, 4),
      is_public_holiday: false,
      is_valid_for_everybody: true,
      display_priority: 3
    })

    # Ascension Day (May 29)
    insert(:public_holiday, %{
      holiday_or_vacation_type_id: holiday_type.id,
      location_id: location_id,
      starts_on: Date.new!(year, 5, 29),
      ends_on: Date.new!(year, 5, 29),
      display_priority: 1
    })

    # Weekend (May 31 - June 1)
    insert(:period, %{
      holiday_or_vacation_type_id: weekend_type.id,
      location_id: location_id,
      starts_on: Date.new!(year, 5, 31),
      ends_on: Date.new!(year, 6, 1),
      is_public_holiday: false,
      is_valid_for_everybody: true,
      display_priority: 3
    })
  end

  # Helper to create periods for multiple years
  def create_periods_for_years(location_id, years, country_id \\ nil) do
    # If country_id is not provided, assume the location is a federal state
    # and get its parent (which should be the country)
    country_id =
      if country_id do
        country_id
      else
        location = MehrSchulferien.Locations.get_location!(location_id)
        location.parent_location_id
      end

    Enum.each(years, fn year ->
      create_test_periods(country_id, location_id, year)
    end)
  end

  # Helper to create vacation periods with specific types
  def create_vacation_periods(location_id, vacation_data) do
    # vacation_data is a list of {type_atom, starts_on, ends_on}
    vacation_types = %{
      oster: insert(:holiday_or_vacation_type, %{name: "Oster", slug: "oster"}),
      herbst: insert(:holiday_or_vacation_type, %{name: "Herbst", slug: "herbst"}),
      weihnachts: insert(:holiday_or_vacation_type, %{name: "Weihnachts", slug: "weihnachts"}),
      winter: insert(:holiday_or_vacation_type, %{name: "Winter", slug: "winter"}),
      sommer: insert(:holiday_or_vacation_type, %{name: "Sommer", slug: "sommer"}),
      pfingst: insert(:holiday_or_vacation_type, %{name: "Pfingst", slug: "pfingst"})
    }

    for {type_atom, starts_on, ends_on} <- vacation_data do
      vacation_type = Map.get(vacation_types, type_atom)

      insert(:school_vacation, %{
        location_id: location_id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: starts_on,
        ends_on: ends_on
      })
    end
  end

  # ============================================================================
  # Blacklist Factories
  # ============================================================================

  def blacklist_verification_request_factory(attrs \\ %{}) do
    {_raw_token, token_hash} = VerificationRequest.generate_token()

    verification_request = %VerificationRequest{
      full_name: sequence(:full_name, &"Test User #{&1}"),
      email: sequence(:email, &"test#{&1}@example.com"),
      token_hash: token_hash,
      expires_at:
        DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.truncate(:second)
    }

    merge_attributes(verification_request, attrs)
  end

  def verified_blacklist_request_factory(attrs \\ %{}) do
    request = blacklist_verification_request_factory(attrs)
    %{request | verified_at: DateTime.utc_now() |> DateTime.truncate(:second)}
  end

  def blacklist_entry_factory(attrs) do
    verification_request = attrs[:verification_request] || insert(:verified_blacklist_request)
    pattern = attrs[:pattern] || "+49 30 1234*"

    entry = %Entry{
      pattern: pattern,
      pattern_regex: MehrSchulferien.Blacklist.PatternMatcher.to_regex_pattern(pattern),
      field_type: attrs[:field_type] || "phone_number",
      requester_name: verification_request.full_name,
      requester_email: verification_request.email,
      verification_request_id: verification_request.id,
      is_active: true
    }

    merge_attributes(entry, attrs)
  end

  def blacklist_removal_log_factory(attrs) do
    entry = attrs[:blacklist_entry] || insert(:blacklist_entry, %{})
    address = attrs[:address] || insert(:address, %{})

    removal_log = %RemovalLog{
      blacklist_entry_id: entry.id,
      address_id: address.id,
      school_location_id: address.school_location_id,
      field_name: entry.field_type,
      original_value: "+49 30 12345678",
      removed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    merge_attributes(removal_log, attrs)
  end
end
