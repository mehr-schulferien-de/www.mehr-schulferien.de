defmodule MehrSchulferien.Repo.Migrations.AddNrwFerientageLimitsUntil20292030 do
  use Ecto.Migration

  import Ecto.Query

  # NRW has published its Ferienordnung through 2029/30, and the number of
  # bewegliche Ferientage changes inside that window: "Neben den landesweit
  # einheitlichen Ferien koennen die Schulen pro Schuljahr drei (2026/27 und
  # 2027/28) beziehungsweise vier bewegliche Ferientage (2028/29 und 2029/30)
  # festlegen." (schulministerium.nrw, checked August 2026)
  #
  # Without these rows the carry-forward in
  # Periods.get_federal_state_ferientage_limit/2 would keep serving 3 into
  # 2028/29, which is the one case where the fallback is quietly wrong rather
  # than merely stale. 2027/28 is recorded too, so the table mirrors the
  # published Ferienordnung instead of a mix of data and fallback.
  @limits [
    {"2027/2028", 3},
    {"2028/2029", 4},
    {"2029/2030", 4}
  ]

  @federal_state_code "NW"

  def up do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()

    rows =
      case federal_state_id(@federal_state_code) do
        nil ->
          []

        federal_state_id ->
          Enum.map(@limits, fn {school_year, max_days} ->
            %{
              federal_state_id: federal_state_id,
              school_year: school_year,
              max_bewegliche_ferientage: max_days,
              inserted_at: now,
              updated_at: now
            }
          end)
      end

    # Empty on a fresh database that has no locations yet, e.g. the test repo.
    unless rows == [] do
      # on_conflict: :nothing keeps a value somebody already corrected by hand.
      repo().insert_all("federal_state_ferientage_limits", rows, on_conflict: :nothing)
    end
  end

  def down do
    case federal_state_id(@federal_state_code) do
      nil ->
        :ok

      federal_state_id ->
        school_years = Enum.map(@limits, fn {school_year, _} -> school_year end)

        repo().delete_all(
          from(l in "federal_state_ferientage_limits",
            where:
              l.federal_state_id == ^federal_state_id and
                l.school_year in ^school_years
          )
        )
    end
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
