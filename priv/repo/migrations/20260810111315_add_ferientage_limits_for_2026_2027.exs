defmodule MehrSchulferien.Repo.Migrations.AddFerientageLimitsFor20262027 do
  use Ecto.Migration

  import Ecto.Query

  # The bewegliche Ferientage limits were entered by hand once, for 2024/2025
  # and 2025/2026 only. When school year 2026/2027 started on 1 August 2026 the
  # lookup found nothing, the school pages stopped offering the entry form and
  # nothing was logged - so the whole feature was off for every federal state.
  #
  # Periods.get_federal_state_ferientage_limit/2 now carries the last known
  # limit forward, which keeps the feature alive on its own. This migration
  # still records 2026/2027 explicitly so the data says what the school year
  # actually is instead of relying on the fallback.
  #
  # Numbers checked against the official sources in August 2026:
  #   BW 4  km.baden-wuerttemberg.de/de/service/ferien
  #   HE 4  schulaemter.hessen.de/schulbesuch/bewegliche-ferientage
  #   NW 3  schulministerium.nrw (3 in 2026/27 and 2027/28, 4 from 2028/29)
  # The remaining states carry their 2025/2026 value unchanged.
  @limits [
    {"BW", 4},
    {"BY", 0},
    {"BE", 0},
    {"BB", 1},
    {"HB", 1},
    {"HH", 0},
    {"HE", 4},
    {"MV", 0},
    {"NI", 0},
    {"NW", 3},
    {"RP", 6},
    {"SL", 2},
    {"SN", 1},
    {"ST", 2},
    {"SH", 2},
    {"TH", 2}
  ]

  @school_year "2026/2027"

  def up do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()

    rows =
      Enum.flat_map(@limits, fn {code, max_days} ->
        case federal_state_id(code) do
          nil ->
            []

          federal_state_id ->
            [
              %{
                federal_state_id: federal_state_id,
                school_year: @school_year,
                max_bewegliche_ferientage: max_days,
                inserted_at: now,
                updated_at: now
              }
            ]
        end
      end)

    # Empty on a fresh database that has no locations yet, e.g. the test repo.
    unless rows == [] do
      # on_conflict: :nothing keeps a value somebody already corrected by hand.
      repo().insert_all("federal_state_ferientage_limits", rows, on_conflict: :nothing)
    end
  end

  def down do
    repo().delete_all(
      from(l in "federal_state_ferientage_limits", where: l.school_year == @school_year)
    )
  end

  defp federal_state_id(code) do
    repo().one(
      from(l in "locations",
        where: l.code == ^code and l.is_federal_state == true,
        select: l.id,
        limit: 1
      )
    )
  end
end
