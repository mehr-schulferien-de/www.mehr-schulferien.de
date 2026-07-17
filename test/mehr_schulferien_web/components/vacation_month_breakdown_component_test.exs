defmodule MehrSchulferienWeb.VacationMonthBreakdownComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.VacationMonthBreakdownComponent

  defp render_breakdown(current_year_data) do
    render_component(&VacationMonthBreakdownComponent.vacation_month_breakdown/1,
      vacation_type: "sommer",
      vacation_config: %{name: "Sommerferien"},
      current_year: 2026,
      current_year_data: current_year_data
    )
  end

  test "groups states under German month names" do
    html =
      render_breakdown([
        %{
          state: %{name: "Hessen", slug: "hessen"},
          period: %{starts_on: ~D[2026-06-29], ends_on: ~D[2026-08-07]}
        },
        %{
          state: %{name: "Bayern", slug: "bayern"},
          period: %{starts_on: ~D[2026-08-03], ends_on: ~D[2026-09-14]}
        },
        %{
          state: %{name: "Berlin", slug: "berlin"},
          period: %{starts_on: ~D[2026-07-09], ends_on: ~D[2026-08-22]}
        }
      ])

    assert html =~ "Juni"
    assert html =~ "Juli"
    refute html =~ "June"
    refute html =~ "July"
  end

  test "sorts month groups chronologically" do
    html =
      render_breakdown([
        %{
          state: %{name: "Bayern", slug: "bayern"},
          period: %{starts_on: ~D[2026-08-03], ends_on: ~D[2026-09-14]}
        },
        %{
          state: %{name: "Hessen", slug: "hessen"},
          period: %{starts_on: ~D[2026-06-29], ends_on: ~D[2026-08-07]}
        }
      ])

    {juni_pos, _} = :binary.match(html, "Juni")
    {august_pos, _} = :binary.match(html, "August")
    assert juni_pos < august_pos
  end
end
