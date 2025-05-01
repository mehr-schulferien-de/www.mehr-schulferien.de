defmodule MehrSchulferienWeb.BridgeDayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferienWeb.Controllers.Helpers.{LocationHelpers, PeriodHelpers}

  def index_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    today = DateHelpers.today_berlin()
    current_year = today.year

    conn
    |> put_status(:moved_permanently)
    |> redirect(
      to:
        Routes.bridge_day_path(
          conn,
          :show_within_federal_state,
          country_slug,
          federal_state_slug,
          current_year
        )
    )
  end

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    with {:ok, year} <- PeriodHelpers.check_year(year),
         {country, federal_state, location_ids} <-
           LocationHelpers.get_locations_and_ids(country_slug, federal_state_slug),
         {:ok, start_date} <- Date.new(year, 1, 1),
         {:ok, end_date} <- Date.new(year, 12, 31),
         true <- PeriodHelpers.has_bridge_days?(location_ids, year) do
      assigns =
        [country: country, federal_state: federal_state, year: year] ++
          PeriodHelpers.list_bridge_day_data(location_ids, start_date, end_date)

      render(conn, "show_within_federal_state.html", assigns)
    else
      # No bridge days for this year
      false ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router

      {:error, :invalid_year} ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router

      _ ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end
  end

  # This function is now in PeriodHelpers, but we'll leave a version here for backward compatibility
  def has_bridge_days?(location_ids, year) do
    PeriodHelpers.has_bridge_days?(location_ids, year)
  end
end
