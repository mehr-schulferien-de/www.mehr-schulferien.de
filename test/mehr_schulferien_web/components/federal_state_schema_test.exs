defmodule MehrSchulferienWeb.FederalStateSchemaTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.FederalState.FaqSchemaComponent

  test "FAQ counts only days within its year and selects the next vacation chronologically" do
    periods = [
      period(~D[2025-12-24], ~D[2026-01-06]),
      period(~D[2026-10-12], ~D[2026-10-23]),
      period(~D[2026-12-24], ~D[2027-01-06]),
      period(~D[2027-08-02], ~D[2027-09-13])
    ]

    html =
      render_component(&FaqSchemaComponent.faq_schema/1,
        federal_state: %{name: "Bayern"},
        year: 2026,
        periods: periods,
        today: ~D[2026-09-19]
      )

    questions =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("script")
      |> Floki.text(js: true)
      |> Jason.decode!()
      |> Map.fetch!("mainEntity")

    count = Enum.find(questions, &String.starts_with?(&1["name"], "Wie viele"))
    assert count["acceptedAnswer"]["text"] =~ "26 Ferientage verteilt auf 3 Ferienabschnitte"
    next = Enum.find(questions, &String.starts_with?(&1["name"], "Wann beginnen"))
    assert next["acceptedAnswer"]["text"] =~ "12.10.2026"
  end

  defp period(first, last) do
    %{
      starts_on: first,
      ends_on: last,
      holiday_or_vacation_type: %{name: "Ferien", default_is_school_vacation: true}
    }
  end
end
