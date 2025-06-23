defmodule MehrSchulferienWeb.Components.PaginationComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.Shared.GenericPaginationComponent

  describe "GenericPaginationComponent for Federal State" do
    test "renders pagination with multiple years" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "bayern"},
        location_type: :federal_state,
        years_with_data: [2023, 2024, 2025],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      assert html =~ "2023"
      assert html =~ "2024"
      assert html =~ "2025"
      # Current year styling
      assert html =~ "bg-blue-600 text-white"
    end

    test "renders single year without pagination arrows" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "bayern"},
        location_type: :federal_state,
        years_with_data: [2024],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      assert html =~ "2024"
      # Disabled arrow icons
      assert html =~ "cursor-not-allowed"
    end

    test "limits visible years to 3 on mobile" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "bayern"},
        location_type: :federal_state,
        years_with_data: [2020, 2021, 2022, 2023, 2024, 2025, 2026],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      # Should show 2023, 2024, 2025 when current is 2024
      assert html =~ "2023"
      assert html =~ "2024"
      assert html =~ "2025"
      refute html =~ "2020"
      refute html =~ "2026"
    end

    test "generates correct federal state routes" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "bayern"},
        location_type: :federal_state,
        years_with_data: [2023, 2024, 2025],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      assert html =~ "/ferien/deutschland/bundesland/bayern/2023"
      assert html =~ "/ferien/deutschland/bundesland/bayern/2025"
    end
  end

  describe "GenericPaginationComponent for City" do
    test "renders pagination with city routes" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "muenchen"},
        location_type: :city,
        years_with_data: [2023, 2024, 2025],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      assert html =~ "/ferien/deutschland/stadt/muenchen/2023"
      assert html =~ "/ferien/deutschland/stadt/muenchen/2025"
      # Current year styling
      assert html =~ "bg-blue-600 text-white"
    end
  end

  describe "GenericPaginationComponent for School" do
    test "renders pagination with school routes" do
      assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "grundschule-test"},
        location_type: :school,
        years_with_data: [2023, 2024, 2025],
        year: 2024
      }

      html = render_component(&GenericPaginationComponent.pagination/1, assigns)

      assert html =~ "/ferien/deutschland/schule/grundschule-test/2023"
      assert html =~ "/ferien/deutschland/schule/grundschule-test/2025"
      # Current year styling
      assert html =~ "bg-blue-600 text-white"
    end
  end

  describe "pagination logic consistency" do
    test "all components handle edge cases consistently" do
      # Test with year at beginning
      years = [2023, 2024, 2025, 2026, 2027]

      federal_state_assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "bayern"},
        location_type: :federal_state,
        years_with_data: years,
        year: 2023
      }

      city_assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "muenchen"},
        location_type: :city,
        years_with_data: years,
        year: 2023
      }

      school_assigns = %{
        conn: build_conn(),
        country: %{slug: "deutschland"},
        location: %{slug: "grundschule-test"},
        location_type: :school,
        years_with_data: years,
        year: 2023
      }

      fs_html = render_component(&GenericPaginationComponent.pagination/1, federal_state_assigns)
      city_html = render_component(&GenericPaginationComponent.pagination/1, city_assigns)
      school_html = render_component(&GenericPaginationComponent.pagination/1, school_assigns)

      # All should show first 3 years when current is first
      for html <- [fs_html, city_html, school_html] do
        assert html =~ "2023"
        assert html =~ "2024"
        assert html =~ "2025"
        refute html =~ "2026"
        refute html =~ "2027"
      end
    end
  end
end
