defmodule MehrSchulferienWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MehrSchulferienWeb.ConnCase, async: true`, although
  this option is not recommendded for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MehrSchulferien.Factory
      import MehrSchulferienWeb.ConnCase

      use Phoenix.VerifiedRoutes,
        endpoint: MehrSchulferienWeb.Endpoint,
        router: MehrSchulferienWeb.Router

      # The default endpoint for testing
      @endpoint MehrSchulferienWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MehrSchulferien.Repo)

    if !tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Helper function to render a component and convert it to a binary string.
  This eliminates the repetitive pattern of calling to_iodata and IO.iodata_to_binary.

  ## Examples

      html = render_to_string(&MyComponent.render/1, %{data: data})
      assert html =~ "Expected content"
  """
  def render_to_string(component, assigns) do
    component
    |> apply([assigns])
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
