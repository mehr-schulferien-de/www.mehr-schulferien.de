defmodule MehrSchulferien.Blacklist.RemovalLog do
  @moduledoc """
  Schema for tracking data removed due to blacklist entries.

  When a blacklist entry is created, matching data is automatically removed
  from existing school addresses. This schema logs each removal for audit
  purposes and potential recovery.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias MehrSchulferien.Blacklist.Entry
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address

  schema "blacklist_removal_logs" do
    field :field_name, :string
    field :original_value, :string
    field :removed_at, :utc_datetime

    belongs_to :blacklist_entry, Entry
    belongs_to :address, Address
    belongs_to :school_location, Location

    timestamps()
  end

  @doc false
  def changeset(removal_log, attrs) do
    removal_log
    |> cast(attrs, [
      :field_name,
      :original_value,
      :removed_at,
      :blacklist_entry_id,
      :address_id,
      :school_location_id
    ])
    |> validate_required([:field_name, :original_value, :removed_at, :blacklist_entry_id])
    |> foreign_key_constraint(:blacklist_entry_id)
    |> foreign_key_constraint(:address_id)
    |> foreign_key_constraint(:school_location_id)
  end

  @doc """
  Creates a changeset for a new removal log entry.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end
end
