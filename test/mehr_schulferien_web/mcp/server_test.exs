defmodule MehrSchulferienWeb.MCP.ServerTest do
  use ExUnit.Case, async: false

  describe "MCP Server" do
    test "server metadata and capabilities" do
      # Test server info
      server_info = MehrSchulferienWeb.MCP.Server.server_info()
      assert server_info["name"] == "MehrSchulferien Data"
      assert server_info["version"] == "1.0.0"

      # Test capabilities
      capabilities = MehrSchulferienWeb.MCP.Server.server_capabilities()
      assert Map.has_key?(capabilities, "tools")
    end

    test "server initializes with registered tools" do
      # Create a new Frame using the constructor
      frame = Hermes.Server.Frame.new()

      # Set up private data as the framework would
      frame = %{
        frame
        | private: %{
            server_module: MehrSchulferienWeb.MCP.Server,
            server_registry: Hermes.Server.Registry,
            __mcp_components__: []
          }
      }

      # Initialize the server
      {:ok, initialized_frame} = MehrSchulferienWeb.MCP.Server.init(%{}, frame)

      # The frame should have components registered in private
      components = initialized_frame.private.__mcp_components__

      # Get tool names from components
      tool_names =
        components
        |> Enum.filter(&match?(%Hermes.Server.Component.Tool{}, &1))
        |> Enum.map(& &1.name)

      # Check core location tools
      assert "get_countries" in tool_names
      assert "get_federal_states" in tool_names
      assert "get_cities_by_state" in tool_names

      # Check vacation/period tools
      assert "get_vacations" in tool_names
      assert "get_public_holidays" in tool_names

      # Check school tools
      assert "get_school_details" in tool_names
      assert "search_schools" in tool_names

      # Check bridge day tools
      assert "get_bridge_days" in tool_names

      # Verify total number of tools
      assert length(tool_names) > 25
    end

    test "Registry is properly configured" do
      # The Registry should be running as part of the application
      assert Process.whereis(Hermes.Server.Registry) != nil
    end
  end
end
