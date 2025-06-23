defmodule MehrSchulferienWeb.LayoutViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.LayoutView

  describe "is_current_page_for_federal_state?/3" do
    test "returns true for matching vacation page" do
      conn = %{path_info: ["ferien", "d", "bundesland", "brandenburg", "2025"]}
      assert LayoutView.is_current_page_for_federal_state?(conn, "brandenburg", 2025)
    end

    test "returns false for different federal state" do
      conn = %{path_info: ["ferien", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_page_for_federal_state?(conn, "bayern", 2025)
    end

    test "returns false for different year" do
      conn = %{path_info: ["ferien", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_page_for_federal_state?(conn, "brandenburg", 2026)
    end

    test "returns false for bridge days page" do
      conn = %{path_info: ["brueckentage", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_page_for_federal_state?(conn, "brandenburg", 2025)
    end
  end

  describe "is_current_bridge_days_page_for_federal_state?/3" do
    test "returns true for matching bridge days page" do
      conn = %{path_info: ["brueckentage", "d", "bundesland", "brandenburg", "2025"]}
      assert LayoutView.is_current_bridge_days_page_for_federal_state?(conn, "brandenburg", 2025)
    end

    test "returns false for different federal state" do
      conn = %{path_info: ["brueckentage", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_bridge_days_page_for_federal_state?(conn, "bayern", 2025)
    end

    test "returns false for different year" do
      conn = %{path_info: ["brueckentage", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_bridge_days_page_for_federal_state?(conn, "brandenburg", 2026)
    end

    test "returns false for vacation page" do
      conn = %{path_info: ["ferien", "d", "bundesland", "brandenburg", "2025"]}
      refute LayoutView.is_current_bridge_days_page_for_federal_state?(conn, "brandenburg", 2025)
    end
  end
end
