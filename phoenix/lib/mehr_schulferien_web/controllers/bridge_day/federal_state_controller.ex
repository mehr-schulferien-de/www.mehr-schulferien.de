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

  alias MehrSchulferien.Timetables.LandingTime

    #=======================


    # Landing to specific federal state.
    # Example: /federal_states/bayern
    #
  def show(conn, %{"id" => id}) do
    starts_on = LandingTime.landing_start_date
    ends_on = LandingTime.landing_end_date
    {federal_state, federal_states, country} = get_locations(id)

    days = CollectBridgeDayData.list_days([country, federal_state],
                                 starts_on: starts_on, ends_on: ends_on)

    starts_on_calendar = Date.add(starts_on,-31)
    ends_on_calendar = Date.add(ends_on,31) 

    #anticipate day(s) of date that are shown on calendar from previous or next month
    days_on_calendar = CollectBridgeDayData.list_days([country, federal_state],
                                  starts_on: starts_on_calendar, ends_on: ends_on_calendar)

    query = from(categories in Category,
                 where: categories.for_anybody == true)
                 
    categories = Repo.all(query)

    compiled_optimal_bridge_days = CollectBridgeDayData.compiled_optimal_bridge_days(days, 1)

    config_investable_day_list = [1,1,1,2,2,2,3,3,3,4,5,6]
    enum_configuration = config_investable_day_list |> Enum.group_by(&(&1))
    best_bridge_days = 
      CollectBridgeDayData.compiled_best_bridge_day_configurable(enum_configuration, days)
      |> List.flatten

    # best bridge_days in one month
    best_bridge_datex = 
      best_bridge_days
      |> Enum.group_by(fn x -> List.first(x[:bridge_days]).month end)

    # the best ratio
    best_bridge_datex2 = for {k, v} <- best_bridge_datex do
        v
        |> Enum.sort_by(fn x -> {length(x[:bridge_days])/x[:bridge_day_vacation_length]} end) 
        |> Enum.take(1) 
    end

    best_bridge_dates = best_bridge_datex2 |> List.flatten

    render(conn, "index.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              days_on_calendar: days_on_calendar,
                              categories: categories,
                              compiled_optimal_bridge_days: compiled_optimal_bridge_days,
                              number_of_days_to_invest: 1,
                              canonical_bridge_days_for_year: starts_on.year,
                              best_bridge_days: best_bridge_days,
                              best_bridge_dates: best_bridge_dates
                              )

    render(conn, "index.html")
  end

    #=======================

  def show(conn, %{"federal_state_id" => federal_state_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on,
                   "number_of_days_to_invest" => number_of_days_to_invest}) do
    {federal_state, federal_states, country} = get_locations(federal_state_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)

    days = CollectBridgeDayData.list_days([country, federal_state],
                                 starts_on: starts_on, ends_on: ends_on)

    starts_on_calendar = Date.add(starts_on,-31)
    ends_on_calendar = Date.add(ends_on,31) 
    
    #anticipate day(s) of date that are shown on calendar from previous or next month
    days_on_calendar = CollectBridgeDayData.list_days([country, federal_state],
                                  starts_on: starts_on_calendar, ends_on: ends_on_calendar)

    query = from(categories in Category,
                 where: categories.for_anybody == true)
    categories = Repo.all(query)

    compiled_optimal_bridge_days = MehrSchulferien.CollectBridgeDayData.compiled_optimal_bridge_days(days, String.to_integer(number_of_days_to_invest))

    # Google meta tags
    #
    rel_prev = nil
    rel_next = nil
    number_of_days_int = String.to_integer(number_of_days_to_invest)
    if number_of_days_int > 0 && number_of_days_int < 9 do
      if number_of_days_int > 1 do
        prev_number_of_days = number_of_days_int - 1
        rel_prev = "/bridge_days/federal_states/#{federal_state.slug}/#{starts_on.year}-01-01/#{starts_on.year}-12-31/#{prev_number_of_days}"
      end
      if number_of_days_int < 8 do
        next_number_of_days = number_of_days_int + 1
        rel_next = "/bridge_days/federal_states/#{federal_state.slug}/#{starts_on.year}-01-01/#{starts_on.year}-12-31/#{next_number_of_days}"
      end
    end

    set_noindex = false
    if number_of_days_int > 8 do
      set_noindex = true
    end

    render(conn, "show.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              days_on_calendar: days_on_calendar,
                              categories: categories,
                              compiled_optimal_bridge_days: compiled_optimal_bridge_days,
                              number_of_days_to_invest: String.to_integer(number_of_days_to_invest),
                              rel_prev: rel_prev,
                              rel_next: rel_next,
                              set_noindex: set_noindex
                              )
  end

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
                              "-12-31/1"
    end
  end

  #=========== page details

  def show(conn, %{"federal_state_id" => federal_state_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on}) do
    {federal_state, federal_states, country} = get_locations(federal_state_id)
    {starts_on, ends_on} = get_dates(starts_on, ends_on)

    days = CollectBridgeDayData.list_days([country, federal_state],
                                 starts_on: starts_on, ends_on: ends_on)
 
    query = from(categories in Category,
                 where: categories.for_anybody == true)
    categories = Repo.all(query)

    render(conn, "detail.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country,
                              starts_on: starts_on,
                              ends_on: ends_on,
                              days: days,
                              categories: categories)
  end
  #============

  # Redirect requests for federal_states to the correct full URL.
  # Example: /federal_states/bayern will become
  #          /federal_states/bayern/2018-01-01/2018-12-31
  #
  # def show(conn, %{"id" => id}) do
  #   federal_state = Locations.get_federal_state!(id)

  #   year_slug = Integer.to_string(DateTime.utc_now.year)
  #   query = from y in Timetables.Year, where: y.slug == ^year_slug
  #   year = Repo.one(query)

  #   case year do
  #     nil -> conn
  #            |> put_status(:not_found)
  #            |> render(MehrSchulferienWeb.ErrorView, "404.html")
  #     _ -> redirect conn, to: "/bridge_days/federal_states/" <>
  #                             federal_state.slug <>
  #                             "/" <>
  #                             year.slug <>
  #                             "-01-01/" <>
  #                             year.slug <>
  #                             "-12-31/1"
  #   end
  # end

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
    query = from c z Category, where: c.for_students == true and
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
