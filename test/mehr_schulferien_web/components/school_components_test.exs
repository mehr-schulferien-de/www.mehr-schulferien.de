defmodule MehrSchulferienWeb.SchoolComponentsTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.SchoolComponents

  describe "schema_org_event/1" do
    test "skips periods without holiday_or_vacation_type" do
      assigns = %{
        periods: [
          %{
            holiday_or_vacation_type: %{colloquial: "Sommerferien"},
            starts_on: ~D[2025-07-01],
            ends_on: ~D[2025-08-31]
          },
          %{
            holiday_or_vacation_type: nil,
            starts_on: ~D[2025-09-01],
            ends_on: ~D[2025-09-05]
          }
        ],
        school: %{name: "Test Gymnasium", address: nil},
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_event/1, assigns)

      # Should only render one script tag for the valid period
      assert html =~ "Sommerferien"
      assert html =~ "2025-07-01"
      refute html =~ "2025-09-01"

      # Count script tags - should be exactly 1
      script_count =
        html
        |> String.split("</script>")
        |> length()
        |> Kernel.-(1)

      assert script_count == 1
    end

    test "handles school with address properly" do
      assigns = %{
        periods: [
          %{
            holiday_or_vacation_type: %{colloquial: "Sommerferien"},
            starts_on: ~D[2025-07-01],
            ends_on: ~D[2025-08-31]
          }
        ],
        school: %{
          name: "Test Gymnasium",
          address: %{
            street: "Teststraße 123",
            zip_code: "01234"
          }
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_event/1, assigns)

      assert html =~ "Teststraße 123"
      assert html =~ "01234"
    end

    test "handles school without address properly" do
      assigns = %{
        periods: [
          %{
            holiday_or_vacation_type: %{colloquial: "Sommerferien"},
            starts_on: ~D[2025-07-01],
            ends_on: ~D[2025-08-31]
          }
        ],
        school: %{
          name: "Test Gymnasium",
          address: nil
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_event/1, assigns)

      # Should have empty strings for address fields
      assert html =~ ~s("streetAddress":"")
      assert html =~ ~s("postalCode":"")
    end

    test "handles school with address but nil fields properly" do
      assigns = %{
        periods: [
          %{
            holiday_or_vacation_type: %{colloquial: "Sommerferien"},
            starts_on: ~D[2025-07-01],
            ends_on: ~D[2025-08-31]
          }
        ],
        school: %{
          name: "Test Gymnasium",
          address: %{
            street: nil,
            zip_code: nil
          }
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_event/1, assigns)

      # Should have empty strings for address fields when they're nil
      assert html =~ ~s("streetAddress":"")
      assert html =~ ~s("postalCode":"")
    end
  end

  describe "schema_org_school/1" do
    test "handles school with full address and geo coordinates" do
      assigns = %{
        school: %{
          name: "Test Gymnasium",
          address: %{
            street: "Teststraße 123",
            zip_code: "01234",
            phone_number: "+49 351 123456",
            email_address: "info@test-gymnasium.de",
            homepage_url: "https://test-gymnasium.de",
            lat: 51.0504,
            lon: 13.7373
          }
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_school/1, assigns)

      assert html =~ "Test Gymnasium"
      assert html =~ "Teststraße 123"
      assert html =~ "01234"
      assert html =~ "+49 351 123456"
      assert html =~ "info@test-gymnasium.de"
      assert html =~ "https://test-gymnasium.de"
      assert html =~ "51.0504"
      assert html =~ "13.7373"
    end

    test "handles school without address" do
      assigns = %{
        school: %{
          name: "Test Gymnasium",
          address: nil
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_school/1, assigns)

      assert html =~ "Test Gymnasium"
      # Should have empty strings for geo coordinates
      assert html =~ ~s("latitude":"")
      assert html =~ ~s("longitude":"")
      # Should not have address block
      refute html =~ "streetAddress"
    end

    test "handles school with address but nil geo coordinates" do
      assigns = %{
        school: %{
          name: "Test Gymnasium",
          address: %{
            street: "Teststraße 123",
            zip_code: "01234",
            phone_number: nil,
            email_address: nil,
            homepage_url: nil,
            lat: nil,
            lon: nil
          }
        },
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&SchoolComponents.schema_org_school/1, assigns)

      assert html =~ "Test Gymnasium"
      assert html =~ "Teststraße 123"
      # Should have empty strings for nil geo coordinates
      assert html =~ ~s("latitude":"")
      assert html =~ ~s("longitude":"")
    end
  end
end
