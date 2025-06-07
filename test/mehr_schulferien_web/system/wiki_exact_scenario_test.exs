defmodule MehrSchulferienWeb.System.WikiExactScenarioTest do
  use MehrSchulferienWeb.ConnCase, async: false

  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Maps.Address

  describe "exact scenario from screenshot" do
    @tag :system
    test "user removes email, homepage AND phone number, should see complete original data in version history" do
      # Create the exact test school mentioned in user scenario
      country = insert(:country, %{slug: "d", name: "Deutschland"})

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

      conn = build_conn()

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302)

      # Step 2: Visit wiki page and check version history
      conn = get(conn, Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)

      # Debug output to see what's happening
      IO.puts("\n=== EXACT SCENARIO DEBUG ===")

      updated_school = Locations.get_school_by_slug!(school.slug)
      versions = PaperTrail.get_versions(updated_school.address) |> Enum.sort_by(& &1.id, :desc)

      IO.puts("Number of versions: #{length(versions)}")
      latest_version = List.first(versions)
      IO.puts("Latest version changes: #{inspect(latest_version.item_changes)}")

      # Extract the version history HTML to see highlighting
      latest_version_pattern = ~r/Version ##{latest_version.id}.*?(?=Version #|\z)/s

      case Regex.run(latest_version_pattern, response) do
        [version_html] ->
          IO.puts("\nLatest version HTML (should show COMPLETE original data):")
          IO.puts(version_html)

        nil ->
          IO.puts("Could not extract version HTML")
      end

      # Step 3: Verify version history shows COMPLETE original data
      # School name
      assert response =~ "Albert Schweitzer Realschule Plus Koblenz"
      # Street
      assert response =~ "Lehrerhohl 46"
      # ZIP/City
      assert response =~ "56077 Koblenz"
      # Original email (should be highlighted)
      assert response =~ "info@rsplus-koblenz.de"
      # Original phone (should be highlighted)
      assert response =~ "+49 261 8896590"
      # Original homepage (should be highlighted)
      assert response =~ "https://rsalb.koblenz.de"

      # Step 4: Verify changed fields are highlighted (this is the key fix)
      # Email should be highlighted since it was removed
      assert response =~ ~r/E-Mail:.*?bg-yellow-100.*?info@rsplus-koblenz\.de/s

      # Phone should be highlighted since it was removed (THIS WAS THE BUG!)
      assert response =~ ~r/Telefon:.*?bg-yellow-100.*?\+49 261 8896590/s

      # Homepage should be highlighted since it was removed
      assert response =~ ~r/Homepage:.*?bg-yellow-100.*?https:\/\/rsalb\.koblenz\.de/s

      IO.puts("\n✅ SUCCESS: Version history correctly shows complete original data for rollback!")
    end
  end
end
