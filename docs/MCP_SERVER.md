# MCP Server Configuration

The MehrSchulferien application includes a Model Context Protocol (MCP) server that provides AI assistants with access to German school vacation and holiday data.

## Configuration

The MCP server can be configured via environment variables or application configuration:

### Environment Variables

- `MCP_ENABLED` - Enable/disable the MCP server (default: `true`)
- `MCP_PORT` - Port for the MCP server (default: `4001`)
- `MCP_AUTO_START` - Auto-start the server transport (default: `false`)

### Application Configuration

In your `config/*.exs` files:

```elixir
config :mehr_schulferien,
  mcp_enabled: true,
  mcp_port: 4001,
  mcp_auto_start: false
```

## Architecture

The MCP server uses the Hermes MCP library and consists of:

1. **Hermes.Server.Registry** - Process registry for MCP components
2. **MehrSchulferienWeb.MCP.Server** - Main server implementation with tools
3. **Transport Layer** - HTTP/SSE transport (configurable)

## Available Tools

The server provides 28+ tools for querying vacation and holiday data:

### Location Tools
- `get_countries` - List all countries
- `get_federal_states` - List federal states
- `get_cities_by_state` - List cities in a federal state
- `get_schools_by_city` - List schools in a city

### Vacation/Holiday Tools
- `get_vacations` - Get vacation periods
- `get_public_holidays` - Get public holidays
- `get_bridge_days` - Calculate optimal bridge days

### School Tools
- `get_school_details` - Get school information
- `search_schools` - Search schools by name

### Export Tools
- `get_ical_url` - Generate iCal URLs
- `export_periods_json` - Export as JSON

## Testing

Run the MCP server tests:

```bash
mix test test/mehr_schulferien_web/mcp/server_test.exs
```

## Usage

When the server is running, AI assistants can connect via the configured transport to access the vacation and holiday data through the standardized MCP protocol.

The server operates with slug-based identifiers (no internal IDs exposed) for security and simplicity.