defmodule MehrSchulferienWeb.VacationPlanner.VacationPlannerCalendarComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.VacationPlanner.VacationPlannerCalendarComponent

  describe "vacation_planner_calendar/1" do
    test "renders every month the result touches, across New Year" do
      assert month_headings(~D[2026-12-19], ~D[2027-02-03]) ==
               ["Dezember 2026", "Januar 2027", "Februar 2027"]
    end

    test "renders a single month for a result inside one month" do
      assert month_headings(~D[2027-05-03], ~D[2027-05-17]) == ["Mai 2027"]
    end
  end

  defp month_headings(start_date, end_date) do
    render_component(&VacationPlannerCalendarComponent.vacation_planner_calendar/1,
      result: %{start_date: start_date, end_date: end_date},
      public_periods: [],
      vacation_dates: []
    )
    |> Floki.parse_fragment!()
    |> Floki.find("th[colspan='7']")
    |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
  end
end
