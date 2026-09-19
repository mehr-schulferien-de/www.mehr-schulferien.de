defmodule MehrSchulferienWeb.ChristmasYearBoundaryTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  alias MehrSchulferienWeb.Helpers.VacationTypeHelpers

  setup do
    country = insert(:country, slug: "d", name: "Deutschland")

    type =
      insert(:holiday_or_vacation_type,
        country_location_id: country.id,
        slug: "weihnachten",
        name: "Weihnachten",
        colloquial: "Weihnachtsferien",
        default_is_school_vacation: true
      )

    for {name, slug, dates} <- [
          {"Hamburg", "hamburg", [{~D[2027-12-20], ~D[2027-12-31]}]},
          {"Bayern", "bayern",
           [{~D[2026-12-21], ~D[2027-01-08]}, {~D[2027-12-24], ~D[2028-01-08]}]},
          {"Berlin", "berlin", [{~D[2026-12-22], ~D[2027-01-02]}]}
        ] do
      state = insert(:federal_state, parent_location_id: country.id, name: name, slug: slug)

      for {first, last} <- dates do
        insert(:period,
          location_id: state.id,
          holiday_or_vacation_type_id: type.id,
          starts_on: first,
          ends_on: last,
          is_school_vacation: true,
          is_valid_for_students: true
        )
      end
    end

    :ok
  end

  test "season year selects by start year and retains the complete cross-year period" do
    rows = VacationTypeHelpers.fetch_vacation_data_for_type("weihnachten", 2027)

    assert Enum.map(rows, &{&1.state.slug, &1.period && &1.period.starts_on}) == [
             {"hamburg", ~D[2027-12-20]},
             {"bayern", ~D[2027-12-24]},
             {"berlin", nil}
           ]

    assert Enum.find(rows, &(&1.state.slug == "bayern")).period.ends_on == ~D[2028-01-08]
  end

  test "national year table, summary and structured data agree across New Year", %{conn: conn} do
    html = conn |> get("/weihnachtsferien/2027?today=19.09.2026") |> html_response(200)
    doc = Floki.parse_document!(html)
    table = doc |> Floki.find("table") |> Floki.text() |> String.replace(~r/\s+/, " ")
    assert table =~ "24.12.2027"
    assert table =~ "08.01.2028"
    refute table =~ "21.12.2026"
    refute table =~ "22.12.2026"
    stats = doc |> Floki.find("dl") |> Floki.text() |> String.replace(~r/\s+/, " ")
    assert stats =~ "Gesamtzeitraum 20 Tage"
    assert stats =~ "Spätester Beginn 24.12.2027"

    schemas =
      doc
      |> Floki.find("script[type='application/ld+json']")
      |> Enum.map(&(Floki.text(&1, js: true) |> Jason.decode!()))

    items = Enum.find(schemas, &(&1["@type"] == "ItemList"))["itemListElement"]
    assert Enum.map(items, & &1["item"]["startDate"]) == ["2027-12-20", "2027-12-24"]
    assert List.last(items)["item"]["endDate"] == "2028-01-08"
  end
end
