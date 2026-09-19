defmodule MehrSchulferienWeb.FerienContentTest do
  use ExUnit.Case, async: true
  alias MehrSchulferienWeb.FerienContent
  import Phoenix.LiveViewTest

  test "active vacation takes priority over a recently completed break" do
    recent = period(~D[2026-10-01], ~D[2026-10-02])
    active = period(~D[2026-10-05], ~D[2026-10-09])

    assert FerienContent.school_return([recent, active], [recent, active], ~D[2026-10-06]) ==
             {active, ~D[2026-10-12]}
  end

  test "visible answer distinguishes a past school return from an upcoming one" do
    summer = period(~D[2026-08-03], ~D[2026-09-14])

    for {today, wording} <- [
          {~D[2026-09-19], "war der erste reguläre Schultag"},
          {~D[2026-09-10], "ist der erste reguläre Schultag"}
        ] do
      html =
        render_component(&MehrSchulferienWeb.FerienContentComponent.school_return/1,
          periods: [summer],
          all_periods: [summer],
          today: today,
          city: %{name: "München"}
        )

      text = html |> Floki.parse_document!() |> Floki.text() |> String.replace(~r/\s+/, " ")
      assert text =~ wording
      assert text =~ "15.09.2026"
    end
  end

  test "school return skips weekends and public holidays after the most recent vacation" do
    summer = period(~D[2026-08-03], ~D[2026-09-14])
    autumn = period(~D[2026-10-17], ~D[2026-10-31])
    holiday = period(~D[2026-11-02], ~D[2026-11-02])

    assert FerienContent.school_return([summer, autumn], [summer, autumn], ~D[2026-09-19]) ==
             {summer, ~D[2026-09-15]}

    assert FerienContent.school_return(
             [summer, autumn],
             [summer, autumn, holiday],
             ~D[2026-10-20]
           ) == {autumn, ~D[2026-11-03]}

    assert FerienContent.school_return([], [], ~D[2026-10-20]) == nil
  end

  test "next vacation and description stay chronological across the year boundary" do
    first = period(~D[2026-10-19], ~D[2026-10-30])
    later = period(~D[2027-02-01], ~D[2027-02-05])
    assert FerienContent.next_period([later, first], ~D[2026-09-19]) == first

    assert FerienContent.description("Bonn", "2026/2027", [later, first], ~D[2026-09-19]) =~
             "19.10.2026"
  end

  defp period(first, last),
    do: %{
      starts_on: first,
      ends_on: last,
      holiday_or_vacation_type: %{name: "Ferien", colloquial: "Schulferien"}
    }
end
