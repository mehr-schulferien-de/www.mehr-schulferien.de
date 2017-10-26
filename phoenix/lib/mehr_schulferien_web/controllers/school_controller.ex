defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Locations.School
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Category
  alias MehrSchulferien.Timetables.InsetDayQuantity
  alias MehrSchulferien.Repo
  alias MehrSchulferien.CollectData
  import Ecto.Query, only: [from: 2]

  # List of schools of a FederalState
  #
  def index(conn, %{"federal_state_id" => federal_state_id}) do
    {federal_state, federal_states, schools} = get_schools(federal_state_id)
    render(conn, "federal_state_schools_index.html", federal_states: federal_states, federal_state: federal_state, schools: schools)
  end

  # List of schools of a Country
  #
  def index(conn, %{"country_id" => country_id}) do
    # country = Locations.get_country!(country_id)
    query = from country in Country, where: country.slug == ^country_id,
                                     preload: [:federal_states, :schools]
    country = Repo.one(query)

    render(conn, "country_schools_index.html", country: country, federal_states: country.federal_states, schools: country.schools)
  end

  def show(conn, %{"id" => id, "additional_categories" => additional_categories}) do
    {school, city, federal_state, country} = get_locations(id)
    {starts_on, ends_on} = get_dates()
    additional_categories = get_additional_categories(additional_categories)

    days = CollectData.list_days([country, federal_state, city, school],
                                 starts_on: starts_on, ends_on: ends_on,
                                 additional_categories: additional_categories)

    render(conn, "show.html", school: school,
                              city: city,
                              federal_state: federal_state,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: additional_categories,
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on),
                              count_inset_day_quantity: CollectData.count_inset_day_quantity(days),
                              nearby_schools: Locations.nearby_schools(school))
  end

  def show(conn, %{"id" => id}) do
    # Check if the slug exists
    #
    query = from schools in School,
            where: schools.slug == ^id
    school = Repo.one(query)

    if school == nil do
      federal_states = Locations.list_federal_states
      zip_code = String.replace(id,~r/-.*$/, "")

      query = from schools in School,
              where: schools.address_zip_code == ^zip_code,
              order_by: [schools.name]
      schools = Repo.all(query)

      conn
      |> put_status(:not_found)
      |> render(MehrSchulferienWeb.ErrorView, "404-school.html", federal_states: federal_states, schools: schools)
    else
      {school, city, federal_state, country} = get_locations(id)
      {starts_on, ends_on} = get_dates()

      days = CollectData.list_days([country, federal_state, city, school],
                                   starts_on: starts_on, ends_on: ends_on)

      render(conn, "show.html", school: school,
                                city: city,
                                federal_state: federal_state,
                                country: country,
                                starts_on: starts_on,
                                ends_on: ends_on,
                                days: days,
                                categories: get_categories(),
                                religion_categories: get_religion_categories(),
                                chosen_religion_categories: [],
                                inset_day_quantity: get_inset_day_quantity(federal_state, starts_on),
                                count_inset_day_quantity: CollectData.count_inset_day_quantity(days),
                                nearby_schools: Locations.nearby_schools(school))
    end
  end

  def show(conn, %{"school_id" => school_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on,
                   "additional_categories" => additional_categories}) do
    {school, city, federal_state, country} = get_locations(school_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)
    additional_categories = get_additional_categories(additional_categories)

    days = CollectData.list_days([country, federal_state, city, school],
                                 starts_on: starts_on, ends_on: ends_on,
                                 additional_categories: additional_categories)

    render(conn, "show.html", school: school,
                              city: city,
                              federal_state: federal_state,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: additional_categories,
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on),
                              count_inset_day_quantity: CollectData.count_inset_day_quantity(days),
                              nearby_schools: Locations.nearby_schools(school))
  end

  def show(conn, %{"school_id" => school_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on}) do
    {school, city, federal_state, country} = get_locations(school_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)

    days = CollectData.list_days([country, federal_state, city, school],
                                 starts_on: starts_on, ends_on: ends_on)

    render(conn, "show.html", school: school,
                              city: city,
                              federal_state: federal_state,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: [],
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on),
                              count_inset_day_quantity: CollectData.count_inset_day_quantity(days),
                              nearby_schools: Locations.nearby_schools(school))
  end

  # Redirect requests for years to the correct full date.
  # Example: /federal_states/bayern/2018 will become
  #          /federal_states/bayern/2018-01-01/2018-12-31

  def show(conn, %{"school_id" => school_id,
                   "year" => year}) do
    school = Locations.get_school!(school_id)

    query = from y in Timetables.Year, where: y.slug == ^year
    year = Repo.one(query)

    case year do
      nil -> conn
             |> put_status(:not_found)
             |> render(MehrSchulferienWeb.ErrorView, "404.html")
      _ -> redirect conn, to: "/schools/" <>
                              school.slug <>
                              "/" <>
                              year.slug <>
                              "-01-01/" <>
                              year.slug <>
                              "-12-31"
    end
  end

  defp get_locations(school_id) do
    query = from schools in School, where: schools.slug == ^school_id,
                                    preload: [:country, :federal_state, :city]
    school = Repo.one(query)
    {school, school.city, school.federal_state, school.country}
  end

  defp get_dates(starts_on \\ nil, ends_on \\ nil) do
    case {starts_on, ends_on} do
      {nil, nil} -> {:ok, starts_on} = Date.from_erl({Date.utc_today.year, Date.utc_today.month, 1})
                    ends_on = Date.add(starts_on, 364)
      {starts_on, ends_on} -> {:ok, starts_on} = Ecto.Date.cast(starts_on)
                              {:ok, ends_on} = Ecto.Date.cast(ends_on)
                              {:ok, starts_on} = Date.from_erl(Ecto.Date.to_erl(starts_on))
                              {:ok, ends_on} = Date.from_erl(Ecto.Date.to_erl(ends_on))
    end

    CollectData.ramp_up_to_full_months(starts_on, ends_on)
  end

  defp get_categories() do
    query = from c in Category, where: c.for_students == true and
                                       "Wochenende" != c.name
    Repo.all(query)
  end

  defp get_religion_categories() do
    query = from c in Category, where: c.for_students == true and
                                       c.is_a_religion == true
    Repo.all(query)
  end

  defp get_additional_categories(additional_categories) do
    additional_categories = String.split(additional_categories, ",")

    query = from(
                 categories in Category,
                 where: categories.slug in ^additional_categories
                )
    Repo.all(query)
  end

  defp get_inset_day_quantity(federal_state, starts_on) do
    year = Timetables.get_year!(starts_on.year)
    query = from idq in InsetDayQuantity, where: idq.federal_state_id == ^federal_state.id and
                                                 idq.year_id == ^year.id
    case Repo.one(query) do
      nil -> 0
      x -> x.value
    end
  end

  defp get_schools(federal_state_id) do
    federal_state = Locations.get_federal_state!(federal_state_id)
    query = from schools in School,
            where: schools.federal_state_id == ^federal_state.id,
            order_by: [schools.name, schools.address_zip_code]
    schools = Repo.all(query)

    query = from fs in FederalState,
            where: fs.country_id == ^federal_state.country_id,
            order_by: [fs.name]
    federal_states = Repo.all(query)
    {federal_state, federal_states, schools}
  end
end
