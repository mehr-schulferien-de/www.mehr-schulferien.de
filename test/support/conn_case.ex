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
  Logs in a wiki user for tests that require authentication.

  ## Example

      setup :log_in_wiki_user

      test "wiki edit requires auth", %{conn: conn} do
        # conn now has a logged in wiki user
      end
  """
  def log_in_wiki_user(%{conn: conn}) do
    user = create_wiki_user()
    conn = log_in_user(conn, user)
    %{conn: conn, current_user: user}
  end

  @doc """
  Creates a wiki user for testing.
  """
  def create_wiki_user(attrs \\ %{}) do
    email = Map.get(attrs, :email, "test-#{System.unique_integer()}@example.com")
    full_name = Map.get(attrs, :full_name, "Test User")

    {:ok, user} =
      MehrSchulferien.Accounts.get_or_create_user_by_email(email, full_name: full_name)

    user
  end

  @doc """
  Logs a user into the connection's session.
  """
  def log_in_user(conn, user) do
    {token, _token_record} = MehrSchulferien.Accounts.create_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:wiki_session_token, token)
    |> Plug.Conn.assign(:current_user, user)
  end
end
