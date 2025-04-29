defmodule MehrSchulferienWeb.BridgeDaySystemTest do
  use MehrSchulferienWeb.FeatureCase

  import MehrSchulferien.Factory
  import Wallaby.Browser

  @current_year Date.utc_today().year
  @future_year @current_year + 1
  @past_year @current_year - 100

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(MehrSchulferien.Repo)
    :ok
  end

  feature "view bridge days for a federal state with data", %{session: session} do
    country = insert(:country, %{code: "DE", name: "Deutschland", slug: "d"})

    federal_state =
      insert(:federal_state, %{
        code: "BB",
        name: "Brandenburg",
        slug: "brandenburg",
        parent_location_id: country.id
      })

    holiday_type =
      insert(:holiday_or_vacation_type, %{name: "Test Holiday", country_location_id: country.id})

    MehrSchulferien.Periods.create_period(%{
      starts_on: Date.new!(@future_year, 1, 1),
      ends_on: Date.new!(@future_year, 1, 1),
      holiday_or_vacation_type_id: holiday_type.id,
      location_id: federal_state.id,
      created_by_email_address: "test@example.com",
      display_priority: 1
    })

    MehrSchulferien.Periods.create_period(%{
      starts_on: Date.new!(@future_year, 5, 1),
      ends_on: Date.new!(@future_year, 5, 1),
      holiday_or_vacation_type_id: holiday_type.id,
      location_id: federal_state.id,
      created_by_email_address: "test@example.com",
      display_priority: 2
    })

    page = session |> visit("/brueckentage/d/bundesland/brandenburg/#{@future_year}")

    assert_has(page, Query.text("Brückentage #{@future_year} in Brandenburg"))
    assert_has(page, Query.text("Die 0 besten Tipps für mehr Urlaub"))
  end

  feature "view bridge days for a federal state without data", %{session: session} do
    country = insert(:country, %{code: "DE", name: "Deutschland", slug: "d"})

    _federal_state =
      insert(:federal_state, %{
        code: "BB",
        name: "Brandenburg",
        slug: "brandenburg",
        parent_location_id: country.id
      })

    page = session |> visit("/brueckentage/d/bundesland/brandenburg/#{@past_year}")
    assert_has(page, Query.text("Not Found"))
  end

  feature "view bridge days for a non-existent federal state", %{session: session} do
    page = session |> visit("/brueckentage/d/bundesland/nonexistent/#{@future_year}")
    assert_has(page, Query.text("Not Found"))
  end

  feature "view bridge days for an invalid year", %{session: session} do
    country = insert(:country, %{code: "DE", name: "Deutschland", slug: "d"})

    _federal_state =
      insert(:federal_state, %{
        code: "BB",
        name: "Brandenburg",
        slug: "brandenburg",
        parent_location_id: country.id
      })

    page = session |> visit("/brueckentage/d/bundesland/brandenburg/foobar")
    assert_has(page, Query.text("Not Found"))
    assert_has(page, Query.text("404"))
  end
end
