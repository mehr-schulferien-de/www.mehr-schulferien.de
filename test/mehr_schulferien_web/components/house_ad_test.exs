defmodule MehrSchulferienWeb.HouseAdTest do
  @moduledoc """
  The house-ad pill under every level-1 heading: it must render the rotating
  vutuv variant with a marked, sponsored click-tracking link — and only there.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MehrSchulferien.Ads

  defp heading(assigns) do
    rendered_to_string(~H"""
    <MehrSchulferienWeb.Shared.TypographyComponent.heading
      level={@level}
      show_ad={@show_ad}
    >
      Schulferien
    </MehrSchulferienWeb.Shared.TypographyComponent.heading>
    """)
  end

  test "a level-1 heading carries the current vutuv ad" do
    html = heading(%{level: 1, show_ad: true})
    ad = Ads.current()

    assert html =~ ad.hook
    assert html =~ ad.label
    assert html =~ ~s(href="/ads/#{ad.id}")
    assert html =~ ~s(rel="sponsored")
    # German ad-labelling duty: the pill is marked as an ad.
    assert html =~ "Anzeige"
    refute html =~ "animina"
  end

  test "show_ad={false} renders no ad" do
    html = heading(%{level: 1, show_ad: false})

    refute html =~ "/ads/"
    refute html =~ "vutuv"
  end

  test "lower heading levels never carry the ad" do
    for level <- 2..6 do
      html = heading(%{level: level, show_ad: true})
      refute html =~ "/ads/"
    end
  end
end
