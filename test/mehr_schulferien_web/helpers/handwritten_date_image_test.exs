defmodule MehrSchulferienWeb.Helpers.HandwrittenDateImageTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.Helpers.HandwrittenDateImage

  defp period(starts_on, ends_on, name) do
    %{starts_on: starts_on, ends_on: ends_on, holiday_or_vacation_type: %{colloquial: name}}
  end

  test "long vacation names stay within the paper width" do
    periods = [
      period(~D[2026-02-16], ~D[2026-02-20], "Frühjahrsferien"),
      period(~D[2026-05-26], ~D[2026-06-05], "Himmelfahrt- und Pfingstferien"),
      period(~D[2026-08-03], ~D[2026-09-14], "Sommerferien"),
      period(~D[2026-11-02], ~D[2026-11-06], "Herbstferien")
    ]

    svg = HandwrittenDateImage.generate_all_vacations_svg(periods, "Bayern", 2026)

    [viewbox_width] =
      Regex.run(~r/viewBox="0 0 (\d+) \d+"/, svg, capture: :all_but_first)

    viewbox_width = String.to_integer(viewbox_width)

    [x, font_size] =
      Regex.run(
        ~r/x="([\d.]+)"[^>]*font-size="([\d.]+)"[^>]*>\s*Himmelfahrt- und Pfingstferien/,
        svg,
        capture: :all_but_first
      )

    x = elem(Float.parse(x), 0)
    font_size = elem(Float.parse(font_size), 0)
    estimated_text_width = String.length("Himmelfahrt- und Pfingstferien") * font_size * 0.52

    assert x + estimated_text_width <= viewbox_width,
           "name would end at #{x + estimated_text_width}px, outside the #{viewbox_width}px paper"
  end
end
