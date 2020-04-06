defmodule MehrSchulferien.Calendars.HolidayOrVacationType do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.{Calendars, NameSlug}
  alias MehrSchulferien.Locations.Location

  schema "holiday_or_vacation_types" do
    field :colloquial, :string
    field :default_html_class, :string
    field :default_is_listed_below_month, :boolean, default: false
    field :default_is_public_holiday, :boolean, default: false
    field :default_is_school_vacation, :boolean, default: false
    field :default_is_valid_for_everybody, :boolean, default: false
    field :default_is_valid_for_students, :boolean, default: false
    field :name, :string
    field :slug, NameSlug.Type
    field :wikipedia_url, :string
    field :default_display_priority, :integer

    belongs_to :country_location, Location
    belongs_to :default_religion, Calendars.Religion

    has_many :periods, Calendars.Period, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(holiday_or_vacation_type, attrs) do
    holiday_or_vacation_type
    |> cast(attrs, [
      :name,
      :colloquial,
      :default_html_class,
      :default_is_listed_below_month,
      :default_is_public_holiday,
      :default_is_school_vacation,
      :default_is_valid_for_everybody,
      :default_is_valid_for_students,
      :wikipedia_url,
      :country_location_id,
      :default_religion_id,
      :default_display_priority
    ])
    |> validate_required([:name, :colloquial, :country_location_id, :default_display_priority])
    |> assoc_constraint(:country_location)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
