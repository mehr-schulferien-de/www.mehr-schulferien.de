defmodule MehrSchulferienWeb.AdControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.AdStat
  alias MehrSchulferien.Ads.Recorder
  alias MehrSchulferien.Repo

  setup do
    start_supervised!({Recorder, flush_interval: :timer.hours(1)})
    :ok
  end

  test "a click redirects to the variant's target and is counted", %{conn: conn} do
    [variant | _] = Ads.variants()

    conn = get(conn, "/ads/#{variant.id}")

    assert redirected_to(conn, 302) == variant.target

    Recorder.flush_now()
    assert [stat] = Repo.all(AdStat)
    assert stat.variant_id == variant.id
    assert stat.clicks == 1
  end

  test "an unknown variant id redirects home without counting", %{conn: conn} do
    conn = get(conn, "/ads/999")

    assert redirected_to(conn, 302) == "/"

    Recorder.flush_now()
    assert Repo.all(AdStat) == []
  end

  test "a non-numeric id redirects home", %{conn: conn} do
    assert conn |> get("/ads/definitely-not-a-number") |> redirected_to(302) == "/"
  end

  test "a page view through the browser pipeline counts one impression", %{conn: conn} do
    get(conn, "/developers")

    Recorder.flush_now()
    assert [stat] = Repo.all(AdStat)
    assert stat.impressions == 1
    assert stat.variant_id == Ads.current().id
  end

  test "the click route itself never counts as an impression", %{conn: conn} do
    [variant | _] = Ads.variants()
    get(conn, "/ads/#{variant.id}")

    Recorder.flush_now()
    assert [stat] = Repo.all(AdStat)
    assert stat.impressions == 0
    assert stat.clicks == 1
  end
end
