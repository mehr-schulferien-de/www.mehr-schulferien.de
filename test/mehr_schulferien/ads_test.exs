defmodule MehrSchulferien.AdsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.AdStat
  alias MehrSchulferien.Ads.Recorder
  alias MehrSchulferien.Calendars.DateHelpers

  describe "variants/0" do
    test "every variant is complete and stable" do
      variants = Ads.variants()

      assert length(variants) >= 2

      for variant <- variants do
        assert is_integer(variant.id)
        assert variant.hook != ""
        assert variant.label != ""
        assert String.starts_with?(variant.target, "https://vutuv.de")
        # The tracking param survives into the vutuv logs.
        assert variant.target =~ "ad=#{variant.id}"
      end

      ids = Enum.map(variants, & &1.id)
      assert Enum.uniq(ids) == ids
    end
  end

  describe "rotation" do
    test "current/0 returns a known variant" do
      assert Ads.current() in Ads.variants()
    end

    test "the pick is deterministic within an hour bucket" do
      assert Ads.variant_for_bucket(42) == Ads.variant_for_bucket(42)
    end

    test "consecutive hour buckets cycle through every variant" do
      seen =
        1..500
        |> Enum.map(&Ads.variant_for_bucket/1)
        |> Enum.uniq()

      assert length(seen) == length(Ads.variants())
    end
  end

  describe "Recorder" do
    setup do
      start_supervised!({Recorder, flush_interval: :timer.hours(1)})
      :ok
    end

    test "aggregates impressions and clicks into one row per day and variant" do
      [variant | _] = Ads.variants()

      Recorder.record(:impressions, variant.id)
      Recorder.record(:impressions, variant.id)
      Recorder.record(:impressions, variant.id)
      Recorder.record(:clicks, variant.id)
      Recorder.flush_now()

      today = DateHelpers.today_berlin()

      assert [stat] = Repo.all(AdStat)
      assert stat.day == today
      assert stat.variant_id == variant.id
      assert stat.impressions == 3
      assert stat.clicks == 1
    end

    test "a second flush increments the same row instead of duplicating it" do
      [variant | _] = Ads.variants()

      Recorder.record(:impressions, variant.id)
      Recorder.flush_now()
      Recorder.record(:impressions, variant.id)
      Recorder.record(:clicks, variant.id)
      Recorder.flush_now()

      assert [stat] = Repo.all(AdStat)
      assert stat.impressions == 2
      assert stat.clicks == 1
    end

    test "an empty flush writes nothing" do
      Recorder.flush_now()
      assert Repo.all(AdStat) == []
    end

    test "record/2 is a silent no-op when the Recorder is not running" do
      stop_supervised!(Recorder)
      assert Recorder.record(:impressions, 3) == :ok
    end
  end

  describe "report/1" do
    test "computes CTR per variant, best first" do
      [first, second | _] = Ads.variants()
      today = DateHelpers.today_berlin()

      insert_stat!(today, first.id, 1000, 5)
      insert_stat!(today, second.id, 1000, 20)

      assert [top, runner_up] = Ads.report(30)

      assert top.variant_id == second.id
      assert top.impressions == 1000
      assert top.clicks == 20
      assert_in_delta top.ctr, 2.0, 0.001
      assert top.hook == second.hook

      assert runner_up.variant_id == first.id
      assert_in_delta runner_up.ctr, 0.5, 0.001
    end

    test "sums across days and ignores days outside the window" do
      [variant | _] = Ads.variants()
      today = DateHelpers.today_berlin()

      insert_stat!(today, variant.id, 100, 1)
      insert_stat!(Date.add(today, -1), variant.id, 100, 1)
      insert_stat!(Date.add(today, -400), variant.id, 100, 99)

      assert [row] = Ads.report(30)
      assert row.impressions == 200
      assert row.clicks == 2
    end

    test "a variant with zero impressions reports zero CTR without crashing" do
      [variant | _] = Ads.variants()
      insert_stat!(DateHelpers.today_berlin(), variant.id, 0, 0)

      assert [row] = Ads.report(30)
      assert row.ctr == 0.0
    end
  end

  defp insert_stat!(day, variant_id, impressions, clicks) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Repo.insert_all(AdStat, [
      %{
        day: day,
        variant_id: variant_id,
        impressions: impressions,
        clicks: clicks,
        inserted_at: now,
        updated_at: now
      }
    ])
  end
end
