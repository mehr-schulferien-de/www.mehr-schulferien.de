defmodule MehrSchulferienWeb.CityController do
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

  # List of cities of a FederalState
  #
  def index(conn, %{"federal_state_id" => federal_state_id}) do
    {federal_state, cities} = get_cities(federal_state_id)
    render(conn, "federal_state_cities_index.html", federal_state: federal_state, cities: cities)
  end

  def show(conn, %{"id" => id, "additional_categories" => additional_categories}) do
    {city, federal_state, country, schools} = get_locations(id)
    {starts_on, ends_on} = get_dates()
    additional_categories = get_additional_categories(additional_categories)

    days = CollectData.list_days([country, federal_state, city],
                                 starts_on: starts_on, ends_on: ends_on,
                                 additional_categories: additional_categories)

    render(conn, "show.html", city: city,
                              federal_state: federal_state,
                              country: country,
                              schools: schools,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: additional_categories,
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on))
  end

  def show(conn, %{"id" => id}) do
    {city, federal_state, country, schools} = get_locations(id)
    {starts_on, ends_on} = get_dates()

    days = CollectData.list_days([country, federal_state, city],
                                 starts_on: starts_on, ends_on: ends_on)

    render(conn, "show.html", city: city,
                              federal_state: federal_state,
                              country: country,
                              schools: schools,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: [],
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on))
  end

  def show(conn, %{"city_id" => city_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on,
                   "additional_categories" => additional_categories}) do
    {city, federal_state, country, schools} = get_locations(city_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)
    additional_categories = get_additional_categories(additional_categories)

    days = CollectData.list_days([country, federal_state, city],
                                 starts_on: starts_on, ends_on: ends_on,
                                 additional_categories: additional_categories)

    render(conn, "show.html", city: city,
                              federal_state: federal_state,
                              country: country,
                              schools: schools,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: additional_categories,
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on))
  end

  def show(conn, %{"city_id" => city_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on}) do
    {city, federal_state, country, schools} = get_locations(city_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)

    days = CollectData.list_days([country, federal_state, city],
                                 starts_on: starts_on, ends_on: ends_on)

    render(conn, "show.html", city: city,
                              federal_state: federal_state,
                              country: country,
                              schools: schools,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: get_categories(),
                              religion_categories: get_religion_categories(),
                              chosen_religion_categories: [],
                              inset_day_quantity: get_inset_day_quantity(federal_state, starts_on))
  end

  # Redirect requests for years to the correct full date.
  # Example: /federal_states/bayern/2018 will become
  #          /federal_states/bayern/2018-01-01/2018-12-31

  def show(conn, %{"city_id" => city_id,
                   "year" => year}) do
    city = Locations.get_city!(city_id)

    query = from y in Timetables.Year, where: y.slug == ^year
    year = Repo.one(query)

    case year do
      nil -> conn
             |> put_status(:not_found)
             |> render(MehrSchulferienWeb.ErrorView, "404.html")
      _ -> redirect conn, to: "/cities/" <>
                              city.slug <>
                              "/" <>
                              year.slug <>
                              "-01-01/" <>
                              year.slug <>
                              "-12-31"
    end
  end

  defp get_locations(city_id) do
    query = from cities in City, where: cities.slug == ^city_id,
                                 preload: [:country, :federal_state, :schools]
    city = Repo.one(query)

    # query = from schools in School, where: schools.city_id == ^city.id
    #
    # schools = Repo.all(query)

    {city, city.federal_state, city.country, city.schools}
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

  defp get_cities(federal_state_id) do
    federal_state = Locations.get_federal_state!(federal_state_id)
    query = from cities in City,
            where: cities.federal_state_id == ^federal_state.id,
            order_by: [cities.name, cities.zip_code]
    cities = Repo.all(query)
    {federal_state, cities}
  end

end
