defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  import MehrSchulferienWeb.Authorize

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Calendars.Period, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  plug :user_check when action in [:new_period, :create_period]

  def new_period(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    user = conn.assigns.current_user
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!(
        "Schulschließung wegen der COVID-19-Pandemie (Corona)"
      )

    changeset = Calendars.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      country: country,
      federal_state: federal_state,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      user_email: user.email
    )
  end

  def create_period(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "period" => period_params
      }) do
    case Calendars.create_period(period_params) do
      {:ok, period} ->
        Email.period_added_notification(period)

        conn
        |> put_flash(
          :info,
          "Die Daten zur Schulschließung wegen der COVID-19-Pandemie wurden eingetragen."
        )
        |> redirect(to: Routes.federal_state_path(conn, :show, country_slug, federal_state_slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        user = conn.assigns.current_user
        country = Locations.get_country_by_slug!(country_slug)
        federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
        country = Locations.get_country_by_slug!(country_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!(
            "Schulschließung wegen der COVID-19-Pandemie (Corona)"
          )

        render(conn, "new.html",
          changeset: changeset,
          country: country,
          federal_state: federal_state,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          user_email: user.email
        )
    end
  end

  # Display all present and future dates for this holiday_or_vacation_type.
  # If no future dates are available, then previous dates are displayed.
  #
  def show_holiday_or_vacation_type(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    today = DateHelpers.today_berlin()

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_slug!(holiday_or_vacation_type_slug)

    periods =
      federal_state
      |> Calendars.list_current_and_future_periods(holiday_or_vacation_type)
      |> check_future_periods(federal_state, holiday_or_vacation_type)

    months = MehrSchulferien.Calendars.DateHelpers.get_months_map()

    render(conn, "show_holiday_or_vacation_type.html",
      country: country,
      federal_state: federal_state,
      holiday_or_vacation_type: holiday_or_vacation_type,
      periods: periods,
      months: months,
      today: today
    )
  end

  defp check_future_periods([], federal_state, holiday_or_vacation_type) do
    case Calendars.list_previous_periods(federal_state, holiday_or_vacation_type) do
      [] -> raise MehrSchulferien.NoHolidayOrVacationTypePeriod
      periods -> periods
    end
  end

  defp check_future_periods(periods, _, _), do: periods

  def show(_conn, %{"modus" => _}) do
    raise MehrSchulferien.InvalidQueryParamsError
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Locations.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    location_ids = [country.id, federal_state.id]
    today = DateHelpers.today_berlin()
    current_year = today.year

    assigns =
      [
        country: country,
        federal_state: federal_state,
        current_year: current_year,
        today: today
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "show.html", assigns)
  end

  def schulbeginn(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    location_ids = [country.id, federal_state.id]
    today = DateHelpers.today_berlin()

    three_month_days =
      for month <- 0..2, do: DateHelpers.create_month(today.year, today.month + month)

    assigns =
      [
        country: country,
        federal_state: federal_state,
        three_month_days: three_month_days,
        today: today
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "schulbeginn.html", assigns)
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    counties = Locations.list_counties(federal_state)

    counties_with_cities =
      Enum.reduce(counties, [], fn county, acc ->
        acc ++ [{county, Locations.list_cities(county)}]
      end)

    location_ids = [country.id, federal_state.id]
    today = DateHelpers.today_berlin()

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
