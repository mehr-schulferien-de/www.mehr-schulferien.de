defmodule MehrSchulferienWeb.JahreskalenderController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Category
  alias MehrSchulferien.Repo
  alias MehrSchulferien.CollectData
  import Ecto.Query, only: [from: 2]


  def show(conn, %{"country_id" => country_id, "year" => year}) do
    country = Locations.get_country!(country_id)
    {starts_on, ends_on} = get_dates(year)
    categories = get_categories()
    federal_states = Locations.list_federal_states

    days = CollectData.list_days([country],
                                 starts_on: starts_on, ends_on: ends_on)

    render(conn, "country_show.html", country: country,
                                      starts_on: starts_on,
                                      ends_on: ends_on,
                                      days: days,
                                      categories: categories,
                                      federal_states: federal_states)
  end

  defp get_dates(year) do
    {:ok, starts_on} = Date.from_erl({String.to_integer(year), 1, 1})
    {:ok, ends_on} = Date.from_erl({String.to_integer(year), 12, 31})
    {starts_on, ends_on}
  end

  defp get_categories() do
    query = from c in Category, where: c.for_students == true and
                                       "Wochenende" != c.name
    Repo.all(query)
  end
end
