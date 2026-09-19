defmodule MehrSchulferienWeb.FaqViewHelpersTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.FaqViewHelpers

  test "weekends are school-free even without stored periods" do
    for date <- [~D[2026-09-19], ~D[2026-09-20]] do
      answer = FaqViewHelpers.is_off_school_answer([], date, %{name: "Bayern"})
      assert answer =~ "Ja,"
      assert answer =~ "Wochenende"
    end

    assert FaqViewHelpers.is_off_school_answer([], ~D[2026-09-21], %{name: "Bayern"}) =~
             "nicht schulfrei"
  end

  test "the next public holiday is chronological, regardless of display priority" do
    periods =
      for {date, name} <- [
            {~D[2027-03-26], "Karfreitag"},
            {~D[2026-10-03], "Tag der Deutschen Einheit"}
          ] do
        %{starts_on: date, ends_on: date, holiday_or_vacation_type: %{colloquial: name}}
      end

    assert FaqViewHelpers.next_public_holiday_answer(%{name: "Bayern"}, periods, ~D[2026-09-19]) ==
             "In 14 Tagen ist Tag der Deutschen Einheit in Bayern."
  end
end
