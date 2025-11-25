defmodule MehrSchulferien.Repo.Migrations.AddPartialIndexesForPeriodQueries do
  use Ecto.Migration

  @doc """
  Add partial indexes to optimize common period queries that use OR conditions.

  The most common query pattern is:
    WHERE (is_public_holiday = true OR is_valid_for_everybody = true)
    AND location_id IN (...)
    AND ends_on >= start_date
    AND starts_on <= end_date

  Partial indexes allow PostgreSQL to use index scans for these filtered queries.
  """
  def change do
    # Index for public holiday periods - used in list_public_everybody_periods
    create index(:periods, [:location_id, :starts_on, :ends_on],
             where: "is_public_holiday = true",
             name: :periods_public_holiday_location_dates_index
           )

    # Index for valid_for_everybody periods - used in list_public_everybody_periods
    create index(:periods, [:location_id, :starts_on, :ends_on],
             where: "is_valid_for_everybody = true",
             name: :periods_everybody_location_dates_index
           )

    # Index for school vacation periods (valid_for_students)
    create index(:periods, [:location_id, :starts_on, :ends_on],
             where: "is_valid_for_students = true",
             name: :periods_students_location_dates_index
           )
  end
end
