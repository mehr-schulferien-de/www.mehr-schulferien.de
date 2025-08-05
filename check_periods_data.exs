# Script to check periods data for 2026
import Ecto.Query
alias MehrSchulferien.{Repo, Periods.Period, Locations.Location}

# Query periods for 2026
query =
  from p in Period,
    where: p.is_school_vacation == true,
    where:
      fragment("? >= ? AND ? <= ?", p.starts_on, ^~D[2026-01-01], p.starts_on, ^~D[2026-12-31]),
    join: l in Location,
    on: p.location_id == l.id,
    select: %{
      period_id: p.id,
      location_id: p.location_id,
      location_name: l.name,
      is_federal_state: l.is_federal_state,
      is_school: l.is_school,
      starts_on: p.starts_on,
      ends_on: p.ends_on,
      vacation_type_id: p.holiday_or_vacation_type_id
    },
    order_by: [desc: l.is_federal_state, asc: l.name]

results = Repo.all(query)

# Group by location type
federal_states = Enum.filter(results, & &1.is_federal_state)
schools = Enum.filter(results, & &1.is_school)

IO.puts("Total periods for 2026: #{length(results)}")
IO.puts("Federal state periods: #{length(federal_states)}")
IO.puts("School periods: #{length(schools)}")

# Show some examples of school periods
if length(schools) > 0 do
  IO.puts("\nExamples of school periods (shouldn't be here):")

  schools
  |> Enum.take(5)
  |> Enum.each(fn period ->
    IO.puts("  Location: #{period.location_name} (ID: #{period.location_id})")
    IO.puts("  Period: #{period.starts_on} to #{period.ends_on}")
    IO.puts("  ---")
  end)
end

# Check 2025 for comparison
query_2025 =
  from p in Period,
    where: p.is_school_vacation == true,
    where:
      fragment("? >= ? AND ? <= ?", p.starts_on, ^~D[2025-01-01], p.starts_on, ^~D[2025-12-31]),
    join: l in Location,
    on: p.location_id == l.id,
    where: l.is_school == true,
    select: count(p.id)

school_count_2025 = Repo.one(query_2025)
IO.puts("\nSchool periods for 2025: #{school_count_2025}")
