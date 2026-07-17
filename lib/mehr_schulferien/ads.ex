defmodule MehrSchulferien.Ads do
  @moduledoc """
  The rotating house ad (currently for vutuv.de) shown in the pill under
  every level-1 heading, plus the measurement that tells us which wording
  works best.

  ## How it works

  * `variants/0` is the fixed list of ad variants. Ids are stable and
    load-bearing: they appear in the click URLs (`/ads/:id`), in the
    `?ad=` param that reaches the vutuv logs, and in the `ad_stats`
    rows — never renumber an id, retire it and add a new one.
  * `current/0` picks the variant for the current hour, deterministically
    (`:erlang.phash2` over the hour bucket). Every render in the same hour
    shows the same variant, so a LiveView's static and connected render
    agree (no flicker) and the hour-of-day bias washes out over the days.
  * Impressions are counted once per page view by
    `MehrSchulferienWeb.Plugs.AdImpressionPlug` (browser pipeline, GET
    only), clicks by `MehrSchulferienWeb.AdController` — both buffered
    through `MehrSchulferien.Ads.Recorder` and flushed into the
    `ad_stats` day/variant counters.
  * `report/1` answers "which ad works best": impressions, clicks and CTR
    per variant over the last N days. On the production server:

        bin/mehr_schulferien remote
        iex> MehrSchulferien.Ads.report(30)

  Small measurement caveats, all uniform across variants (so the CTR
  *comparison* stays fair): page views without a level-1 heading still
  count an impression, and bots that ignore robots.txt count too.
  """

  import Ecto.Query

  alias MehrSchulferien.Ads.AdStat
  alias MehrSchulferien.Ads.Recorder
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Repo

  @variants [
    %{
      id: 3,
      hook: "Ferien geplant? Jetzt die Karriere planen!",
      label: "vutuv.de",
      target: "https://vutuv.de?ad=3"
    },
    %{
      id: 4,
      hook: "Nach den Ferien neuer Job?",
      label: "vutuv.de/jobs",
      target: "https://vutuv.de/jobs?ad=4"
    },
    %{
      id: 5,
      hook: "Im Beruf gefunden werden? Dein kostenloses Profil:",
      label: "vutuv.de",
      target: "https://vutuv.de?ad=5"
    },
    %{
      id: 6,
      hook: "Das offene Business-Netzwerk aus Deutschland. Kostenlos.",
      label: "vutuv.de",
      target: "https://vutuv.de?ad=6"
    }
  ]

  @doc "All ad variants, ids stable (see the moduledoc)."
  def variants, do: @variants

  @doc "The variant with this id, or nil."
  def get_variant(id), do: Enum.find(@variants, &(&1.id == id))

  @doc "The variant every visitor sees during the current hour."
  def current, do: variant_for_bucket(div(System.os_time(:second), 3600))

  @doc """
  The variant for one hour bucket. `phash2` spreads consecutive buckets
  pseudo-randomly over the variants, so no variant is stuck with the same
  hours of the day (which a plain `rem/2` would do whenever the variant
  count divides 24).
  """
  def variant_for_bucket(bucket) do
    Enum.at(@variants, :erlang.phash2(bucket, length(@variants)))
  end

  @doc "Counts one ad impression for the currently shown variant."
  def record_impression, do: Recorder.record(:impressions, current().id)

  @doc "Counts one click on this variant."
  def record_click(%{id: id}), do: Recorder.record(:clicks, id)

  @doc """
  Impressions, clicks and CTR (percent) per variant over the last `days`
  days, best CTR first.
  """
  def report(days \\ 30) do
    since = Date.add(DateHelpers.today_berlin(), -days)

    from(s in AdStat,
      where: s.day >= ^since,
      group_by: s.variant_id,
      select: {s.variant_id, sum(s.impressions), sum(s.clicks)}
    )
    |> Repo.all()
    |> Enum.map(fn {variant_id, impressions, clicks} ->
      %{
        variant_id: variant_id,
        hook: variant_hook(variant_id),
        impressions: impressions,
        clicks: clicks,
        ctr: ctr(clicks, impressions)
      }
    end)
    |> Enum.sort_by(& &1.ctr, :desc)
  end

  defp variant_hook(variant_id) do
    case get_variant(variant_id) do
      nil -> "(retired variant)"
      variant -> variant.hook
    end
  end

  defp ctr(_clicks, impressions) when impressions in [nil, 0], do: 0.0
  defp ctr(clicks, impressions), do: Float.round(clicks / impressions * 100, 3)
end
