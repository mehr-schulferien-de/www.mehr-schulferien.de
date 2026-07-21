defmodule MehrSchulferienWeb.FeiertagControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @year Date.utc_today().year
  @today "01.07.#{@year}"

  defp add_holiday_data(_) do
    country = get_or_create_deutschland()

    brandenburg =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    bayern =
      insert(:federal_state, %{parent_location_id: country.id, slug: "bayern", name: "Bayern"})

    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Tag der Deutschen Einheit",
        slug: "tag-der-deutschen-einheit",
        colloquial: "Tag der Deutschen Einheit",
        default_is_school_vacation: false,
        default_is_public_holiday: true,
        country_location_id: country.id
      })

    state_holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Reformationstag",
        slug: "reformationstag",
        colloquial: "Reformationstag",
        default_is_school_vacation: false,
        default_is_public_holiday: true,
        country_location_id: country.id
      })

    # Country-wide holiday for both years
    for year <- [@year, @year + 1] do
      insert(:period, %{
        location_id: country.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: Date.new!(year, 10, 3),
        ends_on: Date.new!(year, 10, 3),
        is_public_holiday: true,
        is_valid_for_everybody: true,
        is_school_vacation: false,
        is_valid_for_students: false
      })
    end

    # State-only holiday in Brandenburg
    insert(:period, %{
      location_id: brandenburg.id,
      holiday_or_vacation_type_id: state_holiday_type.id,
      starts_on: Date.new!(@year, 10, 31),
      ends_on: Date.new!(@year, 10, 31),
      is_public_holiday: true,
      is_valid_for_everybody: true,
      is_school_vacation: false,
      is_valid_for_students: false
    })

    {:ok, %{country: country, brandenburg: brandenburg, bayern: bayern}}
  end

  describe "state Feiertage year page" do
    setup [:add_holiday_data]

    test "renders the state's holidays for the year", %{conn: conn} do
      conn = get(conn, "/feiertage/d/bundesland/brandenburg/#{@year}?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Feiertage Brandenburg #{@year}"
      assert response =~ "Tag der Deutschen Einheit"
      assert response =~ "Reformationstag"

      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/feiertage/d/bundesland/brandenburg/#{@year}")
    end

    test "past year 301s to the evergreen state Feiertage page", %{conn: conn} do
      conn = get(conn, "/feiertage/d/bundesland/brandenburg/#{@year - 1}?today=#{@today}")

      assert redirected_to(conn, 301) == "/feiertage/d/bundesland/brandenburg"
    end

    test "invalid year is a 404", %{conn: conn} do
      conn = get(conn, "/feiertage/d/bundesland/brandenburg/kalender")

      assert conn.status == 404
    end
  end

  describe "evergreen state Feiertage page" do
    setup [:add_holiday_data]

    test "renders current and next year with self-canonical URL", %{conn: conn} do
      conn = get(conn, "/feiertage/d/bundesland/brandenburg?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Feiertage Brandenburg"
      assert response =~ "Tag der Deutschen Einheit"
      assert response =~ "#{@year + 1}"

      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/feiertage/d/bundesland/brandenburg")
    end

    test "renders FAQPage structured data with the holiday count", %{conn: conn} do
      conn = get(conn, "/feiertage/d/bundesland/brandenburg?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "FAQPage"
      assert response =~ "Wie viele gesetzliche Feiertage"
    end
  end

  describe "national Feiertage pages" do
    setup [:add_holiday_data]

    test "year page lists holidays with the states they apply to", %{conn: conn} do
      conn = get(conn, "/feiertage/d/#{@year}?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Feiertage #{@year}"
      assert response =~ "Tag der Deutschen Einheit"
      # Country-wide holidays are marked as such
      assert response =~ "bundesweit"
      # The Brandenburg-only holiday names its state
      assert response =~ "Reformationstag"

      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/feiertage/d/#{@year}")
    end

    test "evergreen national page renders with self-canonical URL", %{conn: conn} do
      conn = get(conn, "/feiertage/d?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Feiertage"
      assert response =~ "Tag der Deutschen Einheit"
      assert response =~ ~s(rel="canonical" href="https://www.mehr-schulferien.de/feiertage/d")
    end

    test "past national year 301s to the evergreen national page", %{conn: conn} do
      conn = get(conn, "/feiertage/d/#{@year - 1}?today=#{@today}")

      assert redirected_to(conn, 301) == "/feiertage/d"
    end
  end
end
