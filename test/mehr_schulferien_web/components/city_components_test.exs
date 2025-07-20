defmodule MehrSchulferienWeb.CityComponentsTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.CityComponents

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
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&CityComponents.schema_org_event/1, assigns)
      
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

    test "renders all periods with valid holiday_or_vacation_type" do
      assigns = %{
        periods: [
          %{
            holiday_or_vacation_type: %{colloquial: "Sommerferien"},
            starts_on: ~D[2025-07-01],
            ends_on: ~D[2025-08-31]
          },
          %{
            holiday_or_vacation_type: %{colloquial: "Herbstferien"},
            starts_on: ~D[2025-10-01],
            ends_on: ~D[2025-10-15]
          }
        ],
        city: %{name: "Dresden"},
        federal_state: %{name: "Sachsen"},
        country: %{code: "DE"}
      }

      html = render_component(&CityComponents.schema_org_event/1, assigns)
      
      # Should render both periods
      assert html =~ "Sommerferien"
      assert html =~ "2025-07-01"
      assert html =~ "Herbstferien"
      assert html =~ "2025-10-01"
      
      # Count script tags - should be exactly 2
      script_count = 
        html
        |> String.split("</script>")
        |> length()
        |> Kernel.-(1)
      
      assert script_count == 2
    end
  end
end