defmodule MehrSchulferienWeb.Helpers.HandwrittenBridgeDayImageTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.Helpers.HandwrittenBridgeDayImage

  @dates [~D[2026-01-02], ~D[2026-05-15], ~D[2026-06-05], ~D[2026-10-02], ~D[2026-12-28]]

  defp generate(num_bridge_days) do
    holidays =
      @dates
      |> Enum.with_index(1)
      |> Enum.map(fn {date, id} ->
        %{id: id, starts_on: Date.add(date, -1), ends_on: Date.add(date, -1)}
      end)

    bridge_days =
      @dates
      |> Enum.take(num_bridge_days)
      |> Enum.with_index(1)
      |> Enum.map(fn {date, id} -> %{starts_on: date, ends_on: date, last_period_id: id} end)

    HandwrittenBridgeDayImage.generate_svg(%{2 => bridge_days}, "Bayern", 2026, holidays)
  end

  test "uses singular wording when exactly one bridge day is not shown" do
    svg = generate(4)

    assert svg =~ "+ 1 weiterer Brückentag"
    refute svg =~ "1 weitere Brückentage"
  end

  test "keeps plural wording when several bridge days are not shown" do
    svg = generate(5)

    assert svg =~ "+ 2 weitere Brückentage"
  end

  test "renders all text within the viewBox so nothing is cut off" do
    svg = generate(5)

    [_width, height] =
      Regex.run(~r/viewBox="0 0 (\d+) (\d+)"/, svg, capture: :all_but_first)

    max_y = String.to_integer(height)

    y_values =
      ~r/\by="([\d.]+)"/
      |> Regex.scan(svg, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&elem(Float.parse(&1), 0))

    assert y_values != []

    for y <- y_values do
      assert y <= max_y, "text at y=#{y} lies outside the #{max_y}px viewBox"
    end
  end
end
