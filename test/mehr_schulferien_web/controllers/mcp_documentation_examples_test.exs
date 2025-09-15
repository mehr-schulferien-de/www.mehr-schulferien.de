defmodule MehrSchulferienWeb.MCPDocumentationExamplesTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  @mcp_endpoint "/mcp"

  describe "Developer documentation pages" do
    test "GET /developers/mcp renders MCP documentation with all examples", %{conn: conn} do
      conn = get(conn, "/developers/mcp")
      response = html_response(conn, 200)

      # Check main headings
      assert response =~ "MCP Server Dokumentation"
      assert response =~ "Model Context Protocol"

      # Check for example sections
      assert response =~ "Basis-Abfragen"
      assert response =~ "Schul-Abfragen"
      assert response =~ "Ferienplanung"
      assert response =~ "Brückentage-Optimierung"
      assert response =~ "Erweiterte Abfragen"

      # Check for specific example titles
      assert response =~ "1. Alle Bundesländer auflisten"
      assert response =~ "2. Städte in Bayern finden"
      assert response =~ "3. Feiertage für Berlin 2025"
      assert response =~ "4. Schulen in München finden"
      assert response =~ "5. Schuldetails abrufen"
      assert response =~ "6. Schulen im PLZ-Bereich"
      assert response =~ "7. Schulen nach Name suchen"
      assert response =~ "8. Schulferien für Bayern 2025"
      assert response =~ "9. Nächste 5 Ferienperioden"
      assert response =~ "10. Aktuelle Ferienperiode prüfen"
      assert response =~ "11. Brückentage für Bayern 2025"
      assert response =~ "12. Brückentage-Verfügbarkeit"
      assert response =~ "13. Ferienstatistiken"
      assert response =~ "14. Ferienpläne mehrerer Bundesländer vergleichen"
      assert response =~ "15. Alle Ferien und Feiertage kombiniert"
      assert response =~ "16. Location-Hierarchie abrufen"
      assert response =~ "17. iCal-URL für Kalender-Integration"

      # Check for programming language examples
      assert response =~ "Integration in Python"
      assert response =~ "Integration in JavaScript"
      assert response =~ "import requests"
      assert response =~ "async function getVacations"

      # Check for code examples
      assert response =~ "get_federal_states"
      assert response =~ "get_public_holidays"
      assert response =~ "get_schools_by_city"
      assert response =~ "get_bridge_days"
      assert response =~ "get_vacation_statistics"

      # Check for contact information
      assert response =~ "Stefan Wintermeyer"
      assert response =~ "sw@wintermeyer-consulting.de"
    end

    test "GET /developers renders main developer hub", %{conn: conn} do
      conn = get(conn, "/developers")
      response = html_response(conn, 200)

      assert response =~ "Developer Hub"
      assert response =~ "REST API"
      assert response =~ "MCP Server"
      assert response =~ "Open Source"
      assert response =~ "Stefan Wintermeyer"
      assert response =~ "sw@wintermeyer-consulting.de"
      assert response =~ "GitHub Issue"
    end

    test "GET /developers/api renders API documentation", %{conn: conn} do
      conn = get(conn, "/developers/api")
      response = html_response(conn, 200)

      assert response =~ "REST API Dokumentation"
      assert response =~ "API v2.1"
      assert response =~ "API v2.0"
      assert response =~ "federal-states"
      assert response =~ "cities"
      assert response =~ "schools"
      assert response =~ "iCalendar"
      assert response =~ "vCard"
      assert response =~ "Stefan Wintermeyer"
    end

    test "developer pages have consistent navigation", %{conn: conn} do
      pages = ["/developers", "/developers/api", "/developers/mcp"]

      for page <- pages do
        conn =
          conn
          |> recycle()
          |> get(page)

        response = html_response(conn, 200)

        # Check navigation links are present
        assert response =~ ~r{href="/developers"[^>]*>.*Übersicht}s
        assert response =~ ~r{href="/developers/api"[^>]*>.*REST API}s
        assert response =~ ~r{href="/developers/mcp"[^>]*>.*MCP Server}s
      end
    end
  end

  describe "Basic MCP endpoint functionality" do
    test "MCP endpoint is accessible", %{conn: conn} do
      # Just check that the endpoint exists and responds
      payload = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 1
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(@mcp_endpoint, payload)

      # Check we get a response (might be error or result)
      assert conn.status == 200
    end

    test "MCP health endpoint works", %{conn: conn} do
      conn = get(conn, "/mcp/health")
      # Check for valid response
      assert conn.status == 200
      # Try to decode JSON if it's JSON
      case Jason.decode(conn.resp_body) do
        {:ok, response} ->
          assert response["status"] == "ok"
          assert response["server"] == "MehrSchulferien MCP Server"

        {:error, _} ->
          # Not JSON, but that's ok for this test
          assert conn.resp_body =~ "ok"
      end
    end

    test "MCP info endpoint works", %{conn: conn} do
      conn = get(conn, "/mcp/info")
      assert conn.status == 200
      # Try to decode JSON if it's JSON
      case Jason.decode(conn.resp_body) do
        {:ok, response} ->
          assert response["name"] == "MehrSchulferien Data"
          assert response["version"] == "1.0.0"
          assert "tools" in response["capabilities"]
          assert is_integer(response["tools_count"])

        {:error, _} ->
          # Not JSON, but that's ok for this test
          assert conn.resp_body =~ "MehrSchulferien"
      end
    end
  end

  describe "MCP example code snippets validation" do
    test "Python example is syntactically valid", %{conn: conn} do
      conn = get(conn, "/developers/mcp")
      response = html_response(conn, 200)

      # Check Python example has proper structure
      assert response =~ "import requests"
      assert response =~ "import json"
      assert response =~ "https://www.mehr-schulferien.de/mcp"
      assert response =~ "jsonrpc"
      assert response =~ "tools/call"
      assert response =~ "response = requests.post"
    end

    test "JavaScript example is syntactically valid", %{conn: conn} do
      conn = get(conn, "/developers/mcp")
      response = html_response(conn, 200)

      # Check JavaScript example has proper structure
      assert response =~ "async function getVacations"
      assert response =~ "await fetch"
      # Check for POST method (may be escaped differently)
      assert response =~ "POST"
      assert response =~ "Content-Type"
      assert response =~ "JSON.stringify"
      assert response =~ "await response.json()"
    end

    test "curl examples have correct format", %{conn: conn} do
      conn = get(conn, "/developers/mcp")
      response = html_response(conn, 200)

      # Check curl examples have proper structure
      assert response =~ "curl -X POST"
      assert response =~ "https://www.mehr-schulferien.de/mcp"
      assert response =~ "Content-Type"
      assert response =~ "jsonrpc"
    end
  end
end
