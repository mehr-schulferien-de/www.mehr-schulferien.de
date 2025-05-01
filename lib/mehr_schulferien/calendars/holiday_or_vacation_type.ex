defmodule MehrSchulferien.Calendars.HolidayOrVacationType do
  @moduledoc """
  Schema for types of holidays or vacations.

  This schema defines different categories of time-off periods such as:
  - Public holidays (Christmas, New Year, etc.)
  - School vacations (Summer break, Winter break, etc.)
  - Special days (Bridge days, local holidays, etc.)

  Each type has default properties that can be overridden at the period level.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.{Calendars, Slugs.NameSlug, Periods}
  alias MehrSchulferien.Locations.Location

  schema "holiday_or_vacation_types" do
    # Basic attributes
    field :name, :string
    field :colloquial, :string
    field :wikipedia_url, :string

    # Display settings
    field :default_html_class, :string
    field :default_is_listed_below_month, :boolean, default: false
    field :default_display_priority, :integer

    # Type flags - define the nature of this holiday/vacation type
    field :default_is_public_holiday, :boolean, default: false
    field :default_is_school_vacation, :boolean, default: false

    # Validity flags - define who this holiday/vacation type applies to
    field :default_is_valid_for_everybody, :boolean, default: false
    field :default_is_valid_for_students, :boolean, default: false

    # Slugified name for URLs
    field :slug, NameSlug.Type

    # Associations
    belongs_to :country_location, Location
    belongs_to :default_religion, Calendars.Religion

    has_many :periods, Periods.Period, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Changeset for the HolidayOrVacationType schema.

  Validates required fields and generates a unique slug for the holiday/vacation type.
  """
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
