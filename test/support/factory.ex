defmodule MehrSchulferien.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: MehrSchulferien.Repo

  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Period, Religion}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.{Address, ZipCode, ZipCodeMapping}

  def address_factory(attrs) do
    school_id = attrs[:parent_location_id] || insert(:school).id

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

    holiday_or_vacation_type = %HolidayOrVacationType{
      name: name,
      colloquial: "#{name}ferien",
      default_display_priority: 3,
      default_html_class: "green",
      default_is_listed_below_month: true,
      default_is_school_vacation: true,
      default_is_valid_for_students: true,
      wikipedia_url: "https://de.wikipedia.org/wiki/Schulferien##{name}ferien",
      country_location_id: country_id
    }

    merge_attributes(holiday_or_vacation_type, attrs)
  end

  def country_factory do
    %Location{name: "Deutschland", code: "D", is_country: true}
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
      parent_location_id: federal_state_id
    }

    merge_attributes(county, attrs)
  end

  def city_factory(attrs) do
    county_id = attrs[:parent_location_id] || insert(:county).id

    city = %Location{
      name: sequence("Dresden"),
      code: "DR",
      is_city: true,
      parent_location_id: county_id
    }

    merge_attributes(city, attrs)
  end

  def school_factory(attrs) do
    city_id = attrs[:parent_location_id] || insert(:city).id

    school = %Location{
      name: "Kopernikus-Gymnasium",
      is_school: true,
      parent_location_id: city_id
    }

    merge_attributes(school, attrs)
  end

  def period_factory do
    federal_state = insert(:federal_state)

    %Period{
      holiday_or_vacation_type: build(:holiday_or_vacation_type),
      created_by_email_address: "sw@wintermeyer-consulting.de",
      display_priority: 3,
      starts_on: Faker.Date.between(~D[2010-12-01], ~D[2015-12-01]),
      ends_on: Faker.Date.between(~D[2016-12-01], ~D[2019-12-01]),
      location_id: federal_state.id
    }
  end

  def religion_factory do
    name = Enum.random(["Christentum", "Judentum", "Islam"])

    %Religion{
      name: name,
      wikipedia_url: "https://de.wikipedia.org/wiki/#{name}"
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
end
