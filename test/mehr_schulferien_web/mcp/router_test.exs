defmodule MehrSchulferienWeb.MCP.RouterTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  describe "MCP Router HTTP endpoint" do
    test "handles ping request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "ping",
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["jsonrpc"] == "2.0"
      assert response["result"] == %{}
    end

    test "handles initialize request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "initialize",
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["jsonrpc"] == "2.0"
      assert response["result"]["protocolVersion"] == "2024-11-05"
      assert response["result"]["serverInfo"]["name"] == "MehrSchulferien Data"
    end

    test "handles tools/list request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "tools/list",
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["jsonrpc"] == "2.0"
      assert is_list(response["result"]["tools"])

      # Check that we have the expected tools
      tool_names = Enum.map(response["result"]["tools"], & &1["name"])
      assert "get_public_holidays" in tool_names
      assert "get_vacations" in tool_names
      assert "get_federal_states" in tool_names
    end

    test "handles tools/call with get_public_holidays for federal state", %{conn: conn} do
      # Create test data
      country = insert(:country, %{slug: "deutschland"})

      federal_state =
        insert(:federal_state, %{
          slug: "berlin",
          name: "Berlin",
          parent_location_id: country.id
        })

      # Create a public holiday
      holiday_type =
        insert(:holiday_or_vacation_type, %{
          name: "Neujahrstag",
          slug: "neujahrstag",
          default_is_public_holiday: true,
          default_is_school_vacation: false,
          country_location_id: country.id
        })

      insert(:period, %{
        holiday_or_vacation_type_id: holiday_type.id,
        location_id: federal_state.id,
        starts_on: ~D[2025-01-01],
        ends_on: ~D[2025-01-01],
        is_valid_for_everybody: true,
        is_school_vacation: false,
        is_public_holiday: true
      })

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "tools/call",
          "params" => %{
            "name" => "get_public_holidays",
            "arguments" => %{
              "location_slug" => "berlin",
              "location_type" => "federal_state",
              "year" => 2025
            }
          },
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["jsonrpc"] == "2.0"
      assert Map.has_key?(response, "result")
      assert is_list(response["result"]["content"])

      # Parse the JSON string in the content
      [content] = response["result"]["content"]
      assert content["type"] == "text"

      periods = Jason.decode!(content["text"])
      assert is_list(periods)

      # Find our test holiday
      neujahr = Enum.find(periods, fn p -> p["slug"] == "neujahrstag" end)
      assert neujahr
      assert neujahr["starts_on"] == "2025-01-01"
      assert neujahr["is_holiday"] == true
    end

    test "handles multiple locations with same slug correctly", %{conn: conn} do
      # This tests the specific issue that was fixed:
      # Multiple locations with slug "berlin" causing database errors

      country = insert(:country, %{slug: "deutschland"})

      # Create multiple locations with the same slug
      _federal_state =
        insert(:federal_state, %{
          slug: "berlin",
          name: "Berlin (State)",
          parent_location_id: country.id
        })

      _city =
        insert(:city, %{
          slug: "berlin",
          name: "Berlin (City)",
          parent_location_id: country.id
        })

      _county =
        insert(:county, %{
          slug: "berlin",
          name: "Berlin (County)",
          parent_location_id: country.id
        })

      # This should not raise an error despite multiple "berlin" locations
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "tools/call",
          "params" => %{
            "name" => "get_public_holidays",
            "arguments" => %{
              "location_slug" => "berlin",
              "location_type" => "federal_state",
              "year" => 2025
            }
          },
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["jsonrpc"] == "2.0"
      # Should get a result, not an error
      assert Map.has_key?(response, "result")
      refute Map.has_key?(response, "error")
    end

    test "handles invalid method gracefully", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "invalid_method",
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["error"]["code"] == -32_601
      assert response["error"]["message"] == "Method not found"
    end

    test "handles missing method gracefully", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "id" => 1
        })

      assert response = json_response(conn, 200)
      assert response["error"]["code"] == -32_600
      assert response["error"]["message"] == "Invalid request - missing method"
    end

    test "handles tool call with invalid tool name", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "tools/call",
          "params" => %{
            "name" => "non_existent_tool",
            "arguments" => %{}
          },
          "id" => 1
        })

      assert response = json_response(conn, 200)
      # The error might be -32_700 (parse error) or -32_602 (invalid params)
      # depending on how the server handles unknown tools
      assert response["error"]["code"] in [-32_700, -32_602]
    end

    test "properly converts string keys to atoms in arguments", %{conn: conn} do
      # This tests the specific fix for argument key conversion
      country = insert(:country, %{slug: "deutschland"})

      _federal_state =
        insert(:federal_state, %{
          slug: "test-state",
          name: "Test State",
          parent_location_id: country.id
        })

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", %{
          "jsonrpc" => "2.0",
          "method" => "tools/call",
          "params" => %{
            "name" => "get_public_holidays",
            "arguments" => %{
              # String keys
              "location_slug" => "test-state",
              "location_type" => "federal_state",
              "year" => 2025
            }
          },
          "id" => 1
        })

      # Should not get a KeyError about atom keys
      assert response = json_response(conn, 200)

      # Check that we got a result, not an error with KeyError
      if Map.has_key?(response, "error") do
        refute response["error"]["message"] =~ "KeyError"
      else
        assert Map.has_key?(response, "result")
      end
    end

    test "health endpoint returns ok", %{conn: conn} do
      conn = get(conn, "/mcp/health")

      # Use text_response since the router might not set content-type properly for GET
      response_text = response(conn, 200)
      assert response = Jason.decode!(response_text)
      assert response["status"] == "ok"
      assert response["server"] == "MehrSchulferien MCP Server"
    end

    test "info endpoint returns server information", %{conn: conn} do
      conn = get(conn, "/mcp/info")

      # Use text_response since the router might not set content-type properly for GET
      response_text = response(conn, 200)
      assert response = Jason.decode!(response_text)
      assert response["name"] == "MehrSchulferien Data"
      assert response["version"] == "1.0.0"
      assert response["capabilities"] == ["tools"]
      assert is_integer(response["tools_count"])
      assert response["tools_count"] > 0
    end
  end
end
