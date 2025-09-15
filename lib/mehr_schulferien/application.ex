defmodule MehrSchulferien.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Base children that always start
    base_children = [
      {Phoenix.PubSub, name: MehrSchulferien.PubSub},
      MehrSchulferien.Repo,
      MehrSchulferien.Cache
    ]

    # MCP Server children (conditional)
    mcp_children =
      if Application.get_env(:mehr_schulferien, :mcp_enabled, true) do
        [
          # Start Hermes Registry before MCP Server
          Hermes.Server.Registry,
          # MCP Server using its child_spec
          {MehrSchulferienWeb.MCP.Server,
           [
             transport:
               {:streamable_http,
                port: Application.get_env(:mehr_schulferien, :mcp_port, 4001),
                start: Application.get_env(:mehr_schulferien, :mcp_auto_start, false)}
           ]}
        ]
      else
        []
      end

    # Endpoint always starts last
    children = base_children ++ mcp_children ++ [MehrSchulferienWeb.Endpoint]

    opts = [strategy: :one_for_one, name: MehrSchulferien.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    MehrSchulferienWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
