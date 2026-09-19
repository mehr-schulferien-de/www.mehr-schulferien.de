defmodule MehrSchulferienWeb.FerienWidgetControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  setup do
    country = insert(:country, slug: "d", name: "Deutschland")
    state = insert(:federal_state, parent_location_id: country.id, slug: "bayern", name: "Bayern")

    type =
      insert(:holiday_or_vacation_type,
        country_location_id: country.id,
        name: "Herbst",
        colloquial: "Herbstferien",
        default_is_school_vacation: true
      )

    today = MehrSchulferien.Calendars.DateHelpers.today_berlin()

    insert(:period,
      location_id: state.id,
      holiday_or_vacation_type_id: type.id,
      starts_on: Date.add(today, 5),
      ends_on: Date.add(today, 19),
      is_school_vacation: true,
      is_valid_for_students: true
    )

    :ok
  end

  test "setup page has a labelled selector, working preview and escaped embed code", %{conn: conn} do
    html = conn |> get("/ferien-widget?bundesland=bayern") |> html_response(200)
    assert html =~ ~s(name="bundesland")
    assert html =~ ~s(src="/ferien-widget/bayern")
    assert html =~ "&lt;iframe"
    assert html =~ "werbefrei"
  end

  test "embedded calendar is crawlable noindex, frameable, and free of cookies and scripts", %{
    conn: conn
  } do
    conn = get(conn, "/ferien-widget/bayern")
    html = html_response(conn, 200)
    assert html =~ "Herbstferien"
    assert html =~ "Schulferien Bayern"
    assert html =~ "prefers-color-scheme"
    assert html =~ ~s(rel="noopener nofollow")
    assert get_resp_header(conn, "x-frame-options") == []
    assert get_resp_header(conn, "x-robots-tag") == ["noindex, follow"]
    assert get_resp_header(conn, "set-cookie") == []
    refute html =~ "<script"
    refute html =~ "adsbygoogle"
    refute html =~ "csrf-token"
  end

  test "unknown state never falls back to a misleading calendar", %{conn: conn} do
    assert conn |> get("/ferien-widget/kein-bundesland") |> response(404)
  end
end
