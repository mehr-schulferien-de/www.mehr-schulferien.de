defmodule MehrSchulferienWeb.MCP.Router do
  @moduledoc """
  Router for MCP (Model Context Protocol) server.
  Handles HTTP/SSE transport for the MCP protocol.
  """

  use Plug.Router
  require Logger

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  # Main MCP endpoint
  post "/" do
    conn
    |> put_resp_content_type("application/json")
    |> handle_mcp_request()
  end

  # SSE endpoint for server-sent events
  get "/sse" do
    conn
    |> put_resp_content_type("text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_chunked(200)
    |> handle_sse_connection()
  end

  # Health check endpoint
  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "ok", server: "MehrSchulferien MCP Server"}))
  end

  # Server info endpoint
  get "/info" do
    info = %{
      name: "MehrSchulferien Data",
      version: "1.0.0",
      capabilities: ["tools"],
      description: "Access to German school vacation and holiday data",
      tools_count: get_tools_count()
    }

    send_resp(conn, 200, Jason.encode!(info))
  end

  # Catch-all
  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end

  # Private functions

  defp handle_mcp_request(conn) do
    # Get the parsed body from conn.body_params (already parsed by Plug.Parsers)
    request = conn.body_params

    response =
      case request["method"] do
        "initialize" -> handle_initialize(request)
        "tools/list" -> handle_tools_list(request)
        "tools/call" -> handle_tool_call(request)
        "ping" -> handle_ping(request)
        nil -> %{error: %{code: -32600, message: "Invalid request - missing method"}}
        _ -> %{error: %{code: -32601, message: "Method not found"}}
      end

    send_resp(conn, 200, Jason.encode!(response))
  rescue
    e ->
      error_response = %{
        error: %{
          code: -32700,
          message: "Parse error",
          data: inspect(e)
        }
      }

      send_resp(conn, 200, Jason.encode!(error_response))
  end

  defp handle_initialize(_request) do
    %{
      jsonrpc: "2.0",
      result: %{
        protocolVersion: "2024-11-05",
        serverInfo: %{
          name: "MehrSchulferien Data",
          version: "1.0.0"
        },
        capabilities: %{
          tools: %{}
        }
      }
    }
  end

  defp handle_tools_list(_request) do
    tools = get_available_tools()

    %{
      jsonrpc: "2.0",
      result: %{
        tools: tools
      }
    }
  end

  # Known MCP argument keys to prevent atom table exhaustion
  @known_mcp_argument_keys ~w(
    location_slug location_type year country_slug federal_state_slug
    city_slug school_slug query type start_date end_date count
    date distance_meters lat lng limit offset format
    vacation_type religion include_holidays include_vacations
  )a

  defp handle_tool_call(request) do
    tool_name = get_in(request, ["params", "name"])
    arguments = get_in(request, ["params", "arguments"]) || %{}

    # Convert string keys to atoms for the arguments safely (only known keys)
    atomized_arguments =
      for {key, value} <- arguments, reduce: %{} do
        acc ->
          case safe_mcp_key_to_atom(key) do
            {:ok, atom_key} -> Map.put(acc, atom_key, value)
            :error -> acc
          end
      end

    # Create a minimal frame for the server
    frame = %{assigns: %{}}

    case MehrSchulferienWeb.MCP.Server.handle_tool(tool_name, atomized_arguments, frame) do
      {:reply, result, _frame} ->
        %{
          jsonrpc: "2.0",
          result: %{
            content: [
              %{
                type: "text",
                text: Jason.encode!(result)
              }
            ]
          }
        }

      {:error, message, _frame} ->
        %{
          jsonrpc: "2.0",
          error: %{
            code: -32602,
            message: message
          }
        }

      _ ->
        %{
          jsonrpc: "2.0",
          error: %{
            code: -32603,
            message: "Internal error"
          }
        }
    end
  end

  defp safe_mcp_key_to_atom(key) when is_binary(key) do
    try do
      atom = String.to_existing_atom(key)
      if atom in @known_mcp_argument_keys, do: {:ok, atom}, else: :error
    rescue
      ArgumentError -> :error
    end
  end

  defp safe_mcp_key_to_atom(_), do: :error

  defp handle_ping(_request) do
    %{
      jsonrpc: "2.0",
      result: %{}
    }
  end

  defp handle_sse_connection(conn) do
    # Send initial connection event
    chunk(conn, "event: connected\ndata: {\"status\": \"connected\"}\n\n")

    # Keep connection alive with periodic pings
    spawn_link(fn -> sse_keepalive(conn) end)

    conn
  end

  defp sse_keepalive(conn) do
    # Send ping every 30 seconds
    Process.sleep(30_000)
    chunk(conn, "event: ping\ndata: {\"timestamp\": \"#{DateTime.utc_now()}\"}\n\n")
    sse_keepalive(conn)
  rescue
    # Connection closed
    _ -> :ok
  end

  defp get_tools_count do
    length(get_available_tools())
  end

  defp get_available_tools do
    [
      # Location Navigation Tools
      %{
        name: "get_countries",
        description: "List all available countries",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      },
      %{
        name: "get_federal_states",
        description: "List all federal states of a country",
        inputSchema: %{
          type: "object",
          properties: %{
            country_slug: %{type: "string", description: "Country slug (e.g., 'deutschland')"}
          },
          required: ["country_slug"]
        }
      },
      %{
        name: "get_counties",
        description: "List all counties of a federal state",
        inputSchema: %{
          type: "object",
          properties: %{
            country_slug: %{type: "string"},
            federal_state_slug: %{type: "string"}
          },
          required: ["country_slug", "federal_state_slug"]
        }
      },
      %{
        name: "get_cities_by_state",
        description: "List all cities of a federal state",
        inputSchema: %{
          type: "object",
          properties: %{
            country_slug: %{type: "string"},
            federal_state_slug: %{type: "string"}
          },
          required: ["country_slug", "federal_state_slug"]
        }
      },
      %{
        name: "get_cities_by_country",
        description: "List all cities of a country",
        inputSchema: %{
          type: "object",
          properties: %{
            country_slug: %{type: "string"}
          },
          required: ["country_slug"]
        }
      },
      %{
        name: "get_schools_by_city",
        description: "List all schools of a city",
        inputSchema: %{
          type: "object",
          properties: %{
            city_slug: %{type: "string"}
          },
          required: ["city_slug"]
        }
      },
      %{
        name: "get_schools_by_federal_state",
        description: "List all schools in a federal state",
        inputSchema: %{
          type: "object",
          properties: %{
            country_slug: %{type: "string"},
            federal_state_slug: %{type: "string"}
          },
          required: ["country_slug", "federal_state_slug"]
        }
      },

      # School Information Tools
      %{
        name: "get_school_details",
        description: "Get complete school information including address and contact details",
        inputSchema: %{
          type: "object",
          properties: %{
            school_slug: %{type: "string"}
          },
          required: ["school_slug"]
        }
      },
      %{
        name: "search_schools",
        description: "Search schools by name or keyword",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string"},
            federal_state_slug: %{type: "string"},
            city_slug: %{type: "string"}
          },
          required: ["query"]
        }
      },
      %{
        name: "get_nearby_schools",
        description: "Find schools within a certain distance",
        inputSchema: %{
          type: "object",
          properties: %{
            school_slug: %{type: "string"},
            distance_meters: %{type: "integer", minimum: 100, maximum: 50000}
          },
          required: ["school_slug", "distance_meters"]
        }
      },

      # Period Query Tools
      %{
        name: "get_vacations",
        description: "Get school vacation periods for a location",
        inputSchema: %{
          type: "object",
          properties: %{
            location_slug: %{type: "string"},
            location_type: %{type: "string", enum: ["country", "federal_state", "city", "school"]},
            start_date: %{type: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$"},
            end_date: %{type: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$"}
          },
          required: ["location_slug", "location_type"]
        }
      },
      %{
        name: "get_public_holidays",
        description: "Get public holidays for a location",
        inputSchema: %{
          type: "object",
          properties: %{
            location_slug: %{type: "string"},
            location_type: %{type: "string", enum: ["country", "federal_state", "city"]},
            year: %{type: "integer", minimum: 2020, maximum: 2030}
          },
          required: ["location_slug", "location_type", "year"]
        }
      },
      %{
        name: "get_next_periods",
        description: "Get upcoming vacation and holiday periods",
        inputSchema: %{
          type: "object",
          properties: %{
            location_slug: %{type: "string"},
            location_type: %{type: "string"},
            count: %{type: "integer", minimum: 1, maximum: 20}
          },
          required: ["location_slug", "location_type"]
        }
      },
      %{
        name: "get_current_periods",
        description: "Get currently active periods",
        inputSchema: %{
          type: "object",
          properties: %{
            location_slug: %{type: "string"},
            location_type: %{type: "string"},
            date: %{type: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$"}
          },
          required: ["location_slug", "location_type"]
        }
      },

      # Bridge Day Tools
      %{
        name: "get_bridge_days",
        description: "Calculate optimal bridge days for vacation planning",
        inputSchema: %{
          type: "object",
          properties: %{
            federal_state_slug: %{type: "string"},
            year: %{type: "integer", minimum: 2024, maximum: 2030}
          },
          required: ["federal_state_slug", "year"]
        }
      },

      # Statistics Tools
      %{
        name: "get_vacation_statistics",
        description: "Get vacation day statistics for a location",
        inputSchema: %{
          type: "object",
          properties: %{
            location_slug: %{type: "string"},
            location_type: %{type: "string"},
            year: %{type: "integer"}
          },
          required: ["location_slug", "location_type", "year"]
        }
      },

      # Search Tools
      %{
        name: "search_locations",
        description: "Search for any location by name",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string", minLength: 2},
            type: %{
              type: "string",
              enum: ["country", "federal_state", "county", "city", "school"]
            }
          },
          required: ["query"]
        }
      },
      %{
        name: "validate_slug",
        description: "Check if a slug exists and get its type",
        inputSchema: %{
          type: "object",
          properties: %{
            slug: %{type: "string"}
          },
          required: ["slug"]
        }
      }
    ]
  end
end
