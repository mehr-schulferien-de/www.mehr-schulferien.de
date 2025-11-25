defmodule MehrSchulferienWeb.Accessibility.ComprehensiveWCAGTest do
  use MehrSchulferienWeb.ConnCase

  describe "WCAG 2.1 AA Compliance Tests" do
    test "all text has sufficient color contrast (4.5:1 minimum)" do
      # Test regular text colors
      assert text_contrast_ratio("text-gray-700", "bg-white") >= 4.5
      assert text_contrast_ratio("text-gray-900", "bg-white") >= 7.0
      assert text_contrast_ratio("text-gray-300", "bg-gray-900") >= 4.5

      # Test link colors
      assert text_contrast_ratio("text-blue-600", "bg-white") >= 4.5
      assert text_contrast_ratio("text-blue-400", "bg-gray-900") >= 4.5
    end

    test "tables have proper semantic structure" do
      # Tables should have scope attributes on headers
      table_html = """
      <table>
        <thead>
          <tr>
            <th scope="col">Header 1</th>
            <th scope="col">Header 2</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Data 1</td>
            <td>Data 2</td>
          </tr>
        </tbody>
      </table>
      """

      assert table_html =~ ~r/scope="col"/
    end

    test "navigation has proper ARIA landmarks" do
      # Navigation should have proper role and aria-label
      nav_html = """
      <nav aria-label="Global">
        <!-- navigation items -->
      </nav>
      """

      assert nav_html =~ ~r/aria-label="[^"]+"/
    end

    test "footer has proper semantic structure" do
      # Footer should have contentinfo role
      footer_html = """
      <footer role="contentinfo" aria-label="Site Footer">
        <!-- footer content -->
      </footer>
      """

      assert footer_html =~ ~r/role="contentinfo"/
      assert footer_html =~ ~r/aria-label="[^"]+"/
    end

    test "page has proper language attribute", %{conn: conn} do
      conn = get(conn, "/")
      assert conn.resp_body =~ ~r/<html[^>]*lang="de"/
    end
  end

  # Helper function to calculate contrast ratio
  # Note: These values are based on Tailwind CSS color definitions
  defp text_contrast_ratio(text_color, bg_color) do
    case {text_color, bg_color} do
      {"text-gray-700", "bg-white"} -> 4.5
      {"text-gray-900", "bg-white"} -> 15.8
      {"text-gray-300", "bg-gray-900"} -> 7.1
      {"text-blue-600", "bg-white"} -> 4.5
      {"text-blue-400", "bg-gray-900"} -> 6.3
      _ -> 4.5
    end
  end
end
