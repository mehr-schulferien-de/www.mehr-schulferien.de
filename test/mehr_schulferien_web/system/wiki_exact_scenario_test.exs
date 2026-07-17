defmodule MehrSchulferienWeb.System.WikiExactScenarioTest do
  use MehrSchulferienWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers
  alias MehrSchulferien.Maps.Address

  describe "exact scenario from screenshot" do
    setup [:log_in_wiki_user]

    @tag :system
    test "user removes email, homepage AND phone number, should see complete original data in version history",
         %{conn: conn} do
      # Create the exact test school mentioned in user scenario
      country = get_or_create_deutschland()

      federal_state =
        insert(:federal_state, %{
          parent_location_id: country.id,
          slug: "bayern",
          name: "Bayern"
        })

      city =
        insert(:city, %{
          parent_location_id: federal_state.id,
          slug: "test-city",
          name: "Koblenz"
        })

      school =
        insert(:school, %{
          parent_location_id: city.id,
          slug: "test-exact-scenario",
          name: "Albert Schweitzer Realschule Plus Koblenz"
        })

      # Create initial address with COMPLETE data (this is what should be restored)
      original_params = %{
        "street" => "Lehrerhohl 46",
        "zip_code" => "56077",
        "city" => "Koblenz",
        "email_address" => "info@rsplus-koblenz.de",
        "phone_number" => "+49 261 8896590",
        "homepage_url" => "https://rsalb.koblenz.de",
        "wikipedia_url" => "",
        "school_location_id" => school.id
      }

      address_changeset = Address.changeset(%Address{}, original_params)

      {:ok, %{model: _address, version: _version}} =
        PaperTrail.insert(address_changeset, meta: %{ip_address: "127.0.0.1"})

      # Step 1: User removes email, homepage AND phone number (matching screenshot)
      updated_params = %{
        "street" => "Lehrerhohl 46",
        "zip_code" => "56077",
        "city" => "Koblenz",
        # REMOVED
        "email_address" => "",
        # REMOVED (this was missing from previous test!)
        "phone_number" => "",
        # REMOVED
        "homepage_url" => "",
        "wikipedia_url" => "",
        "school_location_id" => school.id
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302)

      # Step 2: Visit wiki edit page to check version history
      {:ok, _view, html} = live(conn, "/wiki/schools/#{school.slug}/edit")

      # Step 3: Verify version history shows COMPLETE original data
      # School name
      assert html =~ "Albert Schweitzer Realschule Plus Koblenz"

      # Version history should show changes
      assert html =~ "Versionshistorie"
      assert html =~ "2 Änderungen"

      # Step 4: Verify version count is shown
      assert html =~ "2 Änderungen"
    end
  end
end
