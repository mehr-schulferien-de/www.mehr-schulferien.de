defmodule MehrSchulferien.Calendars.HolidayOrVacationType do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.NameSlug
  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Maps

  schema "holiday_or_vacation_types" do
    field :colloquial, :string
    field :display_priority, :integer
    field :html_class, :string
    field :listed_below_month, :boolean, default: false
    field :name, :string
    field :needs_approval, :boolean, default: false
    field :public_holiday, :boolean, default: false
    field :school_vacation, :boolean, default: false
    field :slug, NameSlug.Type
    field :valid_for_everybody, :boolean, default: false
    field :valid_for_students, :boolean, default: false
    field :wikipedia_url, :string
    belongs_to :religion, Calendars.Religion
    belongs_to :country_location, Maps.Location

    timestamps()
  end

  @doc false
  def changeset(holiday_or_vacation_type, attrs) do
    holiday_or_vacation_type
    |> cast(attrs, [
      :name,
      :colloquial,
      :slug,
      :html_class,
      :listed_below_month,
      :school_vacation,
      :public_holiday,
      :valid_for_everybody,
      :valid_for_students,
      :needs_approval,
      :wikipedia_url,
      :display_priority,
      :country_location_id
    ])
    |> validate_required([:name, :country_location_id])
    |> assoc_constraint(:country_location)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
