defmodule MehrSchulferien.Timetables.Period do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.Period
  alias MehrSchulferien.Timetables.PeriodSlug
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Locations


  @derive {Phoenix.Param, key: :slug}
  schema "periods" do
    field :ends_on, :date
    field :for_anybody, :boolean, default: false
    field :for_students, :boolean, default: false
    field :is_a_religion, :boolean, default: false
    field :name, :string
    field :needs_exeat, :boolean, default: false
    field :slug, PeriodSlug.Type
    field :source, :string
    field :starts_on, :date
    belongs_to :category, Timetables.Category
    belongs_to :school, Locations.School
    belongs_to :city, Locations.City
    belongs_to :federal_state, Locations.FederalState
    belongs_to :country, Locations.Country

    timestamps()
  end

  @doc false
  def changeset(%Period{} = period, attrs) do
    period
    |> cast(attrs, [:starts_on, :ends_on, :name, :slug, :source, :for_anybody,
                    :for_students, :needs_exeat, :is_a_religion, :category_id,
                    :school_id, :city_id, :federal_state_id, :country_id])
    |> validate_one_of_present([:country_id, :federal_state_id, :city_id,
                                :school_id])
    |> PeriodSlug.set_slug
    |> validate_required([:starts_on, :ends_on, :name, :slug, :for_anybody,
                          :for_students, :needs_exeat, :is_a_religion])
    |> validate_starts_on_is_before_or_equal_ends_on
    |> unique_constraint(:slug)
    |> assoc_constraint(:category)
  end

  defp validate_one_of_present(changeset, fields) do
    fields
    |> Enum.filter(fn field ->
      # Checks if a field is "present".
      # The logic is copied from `validate_required` in Ecto.
      case get_field(changeset, field) do
        nil -> false
        binary when is_binary(binary) -> String.trim_leading(binary) == ""
        _ -> true
      end
    end)
    |> case do
      # Exactly one field was present.
      [field] ->
        without_id = field
                     |> Atom.to_string
                     |> String.replace_suffix("_id", "")
                     |> String.to_existing_atom
        assoc_constraint(changeset, without_id)
      # Zero or more than one fields were present.
      _ ->
        add_error(changeset, hd(fields), "expected exactly one of #{inspect(fields)} to be present")
    end
  end

  defp validate_starts_on_is_before_or_equal_ends_on(changeset) do
    starts_on = get_field(changeset, :starts_on)
    ends_on = get_field(changeset, :ends_on)

    case [starts_on, ends_on] do
      [nil, nil] -> changeset # make sure Date.compare is not called with nil
      [nil, _] -> changeset
      [_, nil] -> changeset
      [_, _] -> case Date.compare(starts_on, ends_on) do
                  :gt -> add_error(changeset, :starts_on, "cannot be later than 'ends_on'")
                  _ -> changeset
                end
    end
  end
end
