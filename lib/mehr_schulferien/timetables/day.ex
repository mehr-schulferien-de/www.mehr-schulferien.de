defmodule MehrSchulferien.Timetables.Day do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MehrSchulferien.Timetables.Day
  alias MehrSchulferien.Timetables.Month
  alias MehrSchulferien.Timetables.Year
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.DaySlug


  @derive {Phoenix.Param, key: :slug}
  schema "days" do
    field :calendar_week, :string
    field :day_of_month, :integer
    field :day_of_year, :integer
    field :slug, DaySlug.Type

    field :value, :date
    field :weekday, :integer
    field :weekday_de, :string
    belongs_to :year, Year
    belongs_to :month, Month

    timestamps()
  end

  @doc false
  def changeset(%Day{} = day, attrs) do
    day
    |> cast(attrs, [:value])
    |> validate_required([:value])
    |> set_weekday
    |> set_weekday_de
    |> set_day_of_year
    |> set_day_of_month
    |> set_year_id
    |> set_month_id
    |> set_calendar_week
    |> DaySlug.set_slug
    |> unique_constraint(:value)
    |> unique_constraint(:slug)
    |> assoc_constraint(:year)
    |> assoc_constraint(:month)
  end

  defp set_weekday(changeset) do
    value = get_field(changeset, :value)
    weekday = Date.day_of_week value

    put_change(changeset, :weekday, weekday)
  end

  defp set_weekday_de(changeset) do
    weekday = get_field(changeset, :weekday)

    weekday_de = case weekday do
      1 -> "Montag"
      2 -> "Dienstag"
      3 -> "Mittwoch"
      4 -> "Donnerstag"
      5 -> "Freitag"
      6 -> "Samstag"
      7 -> "Sonntag"
      _ -> nil
    end

    put_change(changeset, :weekday_de, weekday_de)
  end

  defp set_day_of_year(changeset) do
    value = get_field(changeset, :value)
    put_change(changeset, :day_of_year, day_of_year(value))
  end

  defp day_of_year(value) do
    first_day_of_the_year = Date.from_erl!({value.year, 1, 1})
    Date.diff(value, first_day_of_the_year) + 1
  end

  defp set_day_of_month(changeset) do
    value = get_field(changeset, :value)
    put_change(changeset, :day_of_month, value.day)
  end

  defp set_year_id(changeset) do
    value = get_field(changeset, :value)
    year = Timetables.get_year!(value.year)
    put_change(changeset, :year_id, year.id)
  end

  defp set_month_id(changeset) do
    value = get_field(changeset, :value)
    year_id = get_field(changeset, :year_id)
    query = from f in Month, where: f.year_id == ^year_id,
                             where: f.value == ^value.month
    month = Repo.one(query)
    put_change(changeset, :month_id, month.id)
  end

  defp set_calendar_week(changeset) do
    value = get_field(changeset, :value)
    first_thursday_of_the_year = thursday_of_week(Date.from_erl!({value.year, 1, 4}))
    current_thursday_of_week = thursday_of_week(value)

    calendar_week = round(((day_of_year(current_thursday_of_week) - day_of_year(first_thursday_of_the_year)) / 7) + 1)
    calendar_week = if calendar_week > 51 and value.month == 1 do
      Integer.to_string(value.year - 1) <> "-" <> Integer.to_string(calendar_week)
    else
      Integer.to_string(value.year) <> "-" <> Integer.to_string(calendar_week)
    end
    put_change(changeset, :calendar_week, calendar_week)
  end

  defp thursday_of_week(value) do
    Date.add(Date.add(value, (-1 * Date.day_of_week(value))), 4)
  end

end
