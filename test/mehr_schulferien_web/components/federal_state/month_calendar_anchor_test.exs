defmodule MehrSchulferienWeb.FederalState.MonthCalendarAnchorTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.FederalState.MonthCalendarComponent

  describe "month_calendar/1 anchor ids" do
    test "März gets the URL-safe id 'maerz<year>' that timeline links target" do
      html =
        render_component(&MonthCalendarComponent.month_calendar/1,
          month: 3,
          year: 2026,
          periods: [],
          public_periods: [],
          all_periods: []
        )

      # Timeline links use "#maerz2026"; an id with an umlaut would never match.
      assert html =~ ~s(id="maerz2026")
      refute html =~ ~s(id="märz2026")
    end

    test "regular months keep their plain lowercase id" do
      html =
        render_component(&MonthCalendarComponent.month_calendar/1,
          month: 7,
          year: 2026,
          periods: [],
          public_periods: [],
          all_periods: []
        )

      assert html =~ ~s(id="juli2026")
    end
  end
end
