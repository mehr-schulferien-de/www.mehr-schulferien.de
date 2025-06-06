defmodule MehrSchulferienWeb.RobotsSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  @current_year Date.utc_today().year
  @next_year @current_year + 1
  @past_year @current_year - 2

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "robots.txt" do
    setup [:add_federal_state, :add_periods_for_multiple_years]

    test "robots.txt endpoint returns 200 status and correct content", %{conn: conn} do
      conn = get(conn, "/robots.txt")

      # Check status and content type
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]

      # Check content includes expected parts
      response = response(conn, 200)
      assert response =~ "User-agent: *"
      assert response =~ "Disallow: /api"

      # Check it includes current and next year in the comment
      assert response =~
               "Allow only current year (#{@current_year}) and next year (#{@next_year})"

      # Check that past year URLs are disallowed
      assert response =~ "Disallow: /ferien/*/stadt/*/#{@past_year}$"

      # Check that current and future year URLs are NOT disallowed
      refute response =~ "Disallow: /ferien/*/stadt/*/#{@current_year}$"
      refute response =~ "Disallow: /ferien/*/stadt/*/#{@next_year}$"

      # Check school past year disallow
      assert response =~ "Disallow: /ferien/*/schule/*/#{@past_year}$"

      # Check school current and future year are NOT disallowed
      refute response =~ "Disallow: /ferien/*/schule/*/#{@current_year}$"
      refute response =~ "Disallow: /ferien/*/schule/*/#{@next_year}$"
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods_for_multiple_years(%{federal_state: federal_state}) do
    # Add periods for past year, current year and next year to ensure
    # all these years appear in the database and are processed for robots.txt

    holiday_type = insert(:holiday_or_vacation_type, %{name: "Test Holiday"})

    # Past year period
    create_period(%{
      is_public_holiday: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@past_year, 5, 1),
      ends_on: Date.new!(@past_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Current year period
    create_period(%{
      is_public_holiday: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 5, 1),
      ends_on: Date.new!(@current_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Next year period
    create_period(%{
      is_public_holiday: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@next_year, 5, 1),
      ends_on: Date.new!(@next_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    {:ok, %{federal_state: federal_state}}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
