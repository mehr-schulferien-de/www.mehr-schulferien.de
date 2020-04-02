defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  import MehrSchulferienWeb.Authorize

  alias MehrSchulferien.{Calendars, Calendars.Period, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  plug :user_check when action in [:new_period, :create_period]

  def new_period(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!(
        "Schulschließung wegen der COVID-19-Pandemie (Corona)"
      )

    changeset = Calendars.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      country_slug: country_slug,
      federal_state_slug: federal_state_slug,
      federal_state_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      country: country,
      federal_state: federal_state
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
        country = Locations.get_country_by_slug!(country_slug)
        federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
        country = Locations.get_country_by_slug!(country_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!(
            "Schulschließung wegen der COVID-19-Pandemie (Corona)"
          )

        render(conn, "new.html",
          changeset: changeset,
          country_slug: country_slug,
          federal_state_slug: federal_state_slug,
          federal_state_id: federal_state.id,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          country: country,
          federal_state: federal_state
        )
    end
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
    today = Date.utc_today()

    assigns =
      [
        country: country,
        federal_state: federal_state
      ] ++
        CH.show_period_data(location_ids, today) ++ CH.faq_data(location_ids, today)

    render(conn, "show.html", assigns)
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
    today = Date.utc_today()

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state
      ] ++
        CH.show_period_data(location_ids, today) ++ CH.faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
