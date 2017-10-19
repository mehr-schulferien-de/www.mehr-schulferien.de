defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  def show(conn, %{"id" => id}) do
    federal_state = Locations.get_federal_state!(id)
    federal_states = Locations.list_federal_states
    country = Locations.get_country!(federal_state.country_id)

    render(conn, "show.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country)
  end

  def show(conn, %{"federal_state_id" => federal_state_id,
                   "starts_on" => starts_on,
                   "ends_on" => ends_on}) do
    federal_state = Locations.get_federal_state!(federal_state_id)
    federal_states = Locations.list_federal_states
    country = Locations.get_country!(federal_state.country_id)

    starts_on_day = Timetables.get_day!(starts_on)
    ends_on_day = Timetables.get_day!(ends_on)

    render(conn, "show.html", federal_state: federal_state,
                              federal_states: federal_states,
                              country: country,
                              starts_on_day: starts_on_day,
                              ends_on_day: ends_on_day)
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
      _ -> redirect conn, to: "/federal_states/" <>
                              federal_state.slug <>
                              "/" <>
                              year.slug <>
                              "-01-01/" <>
                              year.slug <>
                              "-12-31"
    end
  end

end
