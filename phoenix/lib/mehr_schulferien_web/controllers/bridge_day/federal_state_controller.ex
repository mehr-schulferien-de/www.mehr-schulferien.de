defmodule MehrSchulferienWeb.BridgeDay.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.InsetDayQuantity
  alias MehrSchulferien.Timetables.Category
  alias MehrSchulferien.Repo
  alias MehrSchulferien.CollectBridgeDayData
  import Ecto.Query, only: [from: 2]


  # def show(conn, %{"id" => id, "additional_categories" => additional_categories}) do
  #   {federal_state, federal_states, country} = get_locations(id)
  #   {starts_on, ends_on} = get_dates()
  #   categories = get_categories()
  #   religion_categories = get_religion_categories()
  #   additional_categories = get_additional_categories(additional_categories)
  #   inset_day_quantity = get_inset_day_quantity(federal_state, starts_on)
  #
  #   days = CollectData.list_days([country, federal_state],
  #                                starts_on: starts_on, ends_on: ends_on)
  #
  #   render(conn, "show.html", federal_state: federal_state,
  #                             federal_states: federal_states,
  #                             country: country,
  #                             starts_on: starts_on,
  #                             ends_on: ends_on,
  #                             days: days,
  #                             categories: categories,
  #                             religion_categories: religion_categories,
  #                             chosen_religion_categories: additional_categories,
  #                             inset_day_quantity: inset_day_quantity)
  # end
  #
  # def show(conn, %{"id" => id}) do
  #   {federal_state, federal_states, country} = get_locations(id)
  #   {starts_on, ends_on} = get_dates()
  #   categories = get_categories()
  #   religion_categories = get_religion_categories()
  #   inset_day_quantity = get_inset_day_quantity(federal_state, starts_on)
  #
  #   days = CollectData.list_days([country, federal_state],
  #                                starts_on: starts_on, ends_on: ends_on)
  #
  #   render(conn, "show.html", federal_state: federal_state,
  #                             federal_states: federal_states,
  #                             country: country,
  #                             starts_on: starts_on,
  #                             ends_on: ends_on,
  #                             days: days,
  #                             categories: categories,
  #                             religion_categories: religion_categories,
  #                             chosen_religion_categories: [],
  #                             inset_day_quantity: inset_day_quantity)
  # end
  #
  # def show(conn, %{"federal_state_id" => federal_state_id,
  #                  "starts_on" => starts_on,
  #                  "ends_on" => ends_on,
  #                  "additional_categories" => additional_categories}) do
  #   {federal_state, federal_states, country} = get_locations(federal_state_id)
  #   {starts_on, ends_on} = get_dates(starts_on, ends_on)
  #   categories = get_categories()
  #   religion_categories = get_religion_categories()
  #   additional_categories = get_additional_categories(additional_categories)
  #   inset_day_quantity = get_inset_day_quantity(federal_state, starts_on)
  #
  #   days = CollectData.list_days([country, federal_state],
  #                                starts_on: starts_on, ends_on: ends_on)
  #
  #   render(conn, "show.html", federal_state: federal_state,
  #                             federal_states: federal_states,
  #                             country: country,
  #                             starts_on: starts_on,
  #                             ends_on: ends_on,
  #                             days: days,
  #                             categories: categories,
  #                             religion_categories: religion_categories,
  #                             chosen_religion_categories: additional_categories,
  #                             inset_day_quantity: inset_day_quantity)
  # end

  def show(conn, %{"federal_state_id" => federal_state_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on,
                   "number_of_days_to_invest" => number_of_days_to_invest}) do
    {federal_state, federal_states, country} = get_locations(federal_state_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)

    days = CollectBridgeDayData.list_days([country, federal_state],
                                 starts_on: starts_on, ends_on: ends_on)

    query = from(categories in Category,
                 where: categories.for_anybody == true)
    categories = Repo.all(query)

    compiled_optimal_bridge_days = MehrSchulferien.CollectBridgeDayData.compiled_optimal_bridge_days(days, String.to_integer(number_of_days_to_invest))

    render(conn, "show.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: categories,
                              compiled_optimal_bridge_days: compiled_optimal_bridge_days,
                              number_of_days_to_invest: String.to_integer(number_of_days_to_invest))
  end

  # Redirect requests for years to the correct full date.
  # Example: /federal_states/bayern/2018 will become
  #          /federal_states/bayern/2018-01-01/2018-12-31
  #
  def show(conn, %{"federal_state_id" => federal_state_id,
                   "year" => year}) do
    federal_state = Locations.get_federal_state!(federal_state_id)

    query = from y in Timetables.Year, where: y.slug == ^year
    year = Repo.one(query)

    case year do
      nil -> conn
             |> put_status(:not_found)
             |> render(MehrSchulferienWeb.ErrorView, "404.html")
      _ -> redirect conn, to: "/bridge_days/federal_states/" <>
                              federal_state.slug <>
                              "/" <>
                              year.slug <>
                              "-01-01/" <>
                              year.slug <>
                              "-12-31"
    end
  end

  defp get_locations(federal_state_id) do
    query = from fs in FederalState, where: fs.slug == ^federal_state_id,
                                     preload: [:country]
    federal_state = Repo.one(query)
    federal_states = Locations.list_federal_states
    {federal_state, federal_states, federal_state.country}
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

    CollectBridgeDayData.ramp_up_to_full_months(starts_on, ends_on)
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

end
