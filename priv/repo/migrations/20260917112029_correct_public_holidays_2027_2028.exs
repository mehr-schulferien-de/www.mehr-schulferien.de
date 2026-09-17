defmodule MehrSchulferien.Repo.Migrations.CorrectPublicHolidays20272028 do
  use Ecto.Migration

  import Ecto.Query

  # The July 2025 import for 2026/2027 and 2027/2028 got the public holidays
  # wrong in three ways, all visible on the Feiertage pages:
  #
  # 1. The KMK table lists school-free days such as the Friday after Christi
  #    Himmelfahrt next to the holiday. The import stored them as public
  #    holidays too, so Christi Himmelfahrt and Pfingstmontag showed up twice.
  #    Each of those days is also stored as a school vacation, which stays.
  # 2. Hamburg's single Winterferien day went in as a public holiday.
  # 3. The holidays after the summer were never added for 2027 and 2028.

  @real_dates %{
    "christi-himmelfahrt" => [~D[2027-05-06], ~D[2028-05-25]],
    "pfingstmontag" => [~D[2027-05-17], ~D[2028-06-05]]
  }

  @after_summer [
    {"weltkindertag", 9, 20, ~w(TH)},
    {"reformationstag", 10, 31, ~w(BB HB HH MV NI SN ST SH TH)},
    {"allerheiligen", 11, 1, ~w(BW BY NW RP SL)}
  ]

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    for {slug, dates} <- @real_dates do
      repo().delete_all(
        from(p in "periods",
          as: :holiday,
          join: t in "holiday_or_vacation_types",
          on: t.id == p.holiday_or_vacation_type_id,
          where: t.slug == ^slug and p.is_public_holiday,
          where: p.starts_on >= ^~D[2027-01-01] and p.starts_on <= ^~D[2028-12-31],
          where: p.starts_on not in type(^dates, {:array, :date}),
          where: exists(school_vacation_on_holiday())
        )
      )
    end

    repo().update_all(
      from(p in "periods",
        join: t in "holiday_or_vacation_types",
        on: t.id == p.holiday_or_vacation_type_id,
        where: t.default_is_school_vacation and p.is_public_holiday
      ),
      set: [
        is_school_vacation: true,
        is_valid_for_students: true,
        is_public_holiday: false,
        is_valid_for_everybody: false,
        display_priority: 5,
        updated_at: now
      ]
    )

    state_ids = ids(from(l in "locations", where: l.is_federal_state, select: {l.code, l.id}))
    type_ids = ids(from(t in "holiday_or_vacation_types", select: {t.slug, t.id}))

    rows =
      for year <- [2027, 2028],
          {slug, month, day, codes} <- @after_summer,
          code <- codes,
          state_id = state_ids[code],
          type_id = type_ids[slug],
          state_id && type_id do
        date = Date.new!(year, month, day)

        %{
          starts_on: date,
          ends_on: date,
          location_id: state_id,
          holiday_or_vacation_type_id: type_id,
          is_public_holiday: true,
          is_valid_for_everybody: true,
          is_valid_for_students: true,
          is_school_vacation: false,
          is_listed_below_month: true,
          display_priority: 10,
          created_by_email_address: "claude@anthropic.com",
          inserted_at: now,
          updated_at: now
        }
      end

    # on_conflict: :nothing keeps a holiday somebody already added by hand.
    repo().insert_all("periods", rows, on_conflict: :nothing)
  end

  # The corrected holidays are the statutory ones; rolling back must not
  # bring the wrong ones back.
  def down, do: :ok

  defp school_vacation_on_holiday do
    from(v in "periods",
      where: v.location_id == parent_as(:holiday).location_id and v.is_school_vacation,
      where:
        v.starts_on <= parent_as(:holiday).starts_on and
          v.ends_on >= parent_as(:holiday).starts_on,
      select: 1
    )
  end

  defp ids(query), do: query |> repo().all() |> Map.new()
end
