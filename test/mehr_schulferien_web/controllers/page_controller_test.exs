defmodule MehrSchulferienWeb.PageControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    country = insert(:country, %{slug: "d"})
    federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})

    for federal_state <- federal_states do
      add_periods(%{federal_state: federal_state})
    end

    {:ok, %{conn: conn}}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Aktuelle Schulferien und Feiertage"
  end

  test "custom meta tags are generated", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200) =~
             "Schulferienkalender und gesetzliche Feiertage für Deutschland"
  end

  defp add_periods(%{federal_state: federal_state}) do
    _school_periods = add_school_periods(%{location: federal_state})
    _public_periods = add_public_periods(%{location: federal_state})
  end
end
