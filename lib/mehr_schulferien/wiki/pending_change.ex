defmodule MehrSchulferien.Wiki.PendingChange do
  @moduledoc """
  Schema for pending wiki changes that require approval before being applied.

  This implements a "second pair of eyes" workflow where wiki changes are stored
  in a pending queue and only applied after admin approval via magic links.

  ## Change Types

  - `create_school` - New school creation
  - `update_school` - School update (name, address fields)
  - `delete_school` - School deletion
  - `create_period` - New period/vacation date
  - `update_period` - Period update
  - `delete_period` - Period deletion
  - `create_beweglicher_ferientag` - New beweglicher Ferientag
  - `update_beweglicher_ferientag` - Update beweglicher Ferientag
  - `delete_beweglicher_ferientag` - Delete beweglicher Ferientag

  ## Workflow

  1. User submits change via wiki form
  2. Change is stored in pending_changes table (NOT applied to live data)
  3. Admin email sent with approve/reject magic links
  4. On approval: changes applied to live database via PaperTrail
  5. On rejection: pending change marked as rejected (no user notification)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_change_types ~w(
    create_school update_school delete_school
    create_period update_period delete_period
    create_beweglicher_ferientag update_beweglicher_ferientag delete_beweglicher_ferientag
  )

  @valid_statuses ~w(pending approved rejected)

  schema "pending_changes" do
    # Type of change being requested
    field :change_type, :string

    # JSON payload containing all change data
    # For creates: all fields needed to create the record
    # For updates: both old and new values for changed fields
    # For deletes: record data for reference
    field :payload, :map

    # For updates/deletes: ID of the existing record being modified
    field :original_record_id, :integer

    # IP address of the user who submitted the change
    field :submitted_by_ip, :string

    # Current status: pending, approved, rejected
    field :status, :string, default: "pending"

    # Unique tokens for magic links
    field :approval_token, :string
    field :rejection_token, :string

    # Timestamp when the change was reviewed (approved or rejected)
    field :reviewed_at, :utc_datetime

    # Optional note from reviewer
    field :reviewer_note, :string

    timestamps()
  end

  @doc """
  Changeset for creating a new pending change.
  """
  def changeset(pending_change, attrs) do
    pending_change
    |> cast(attrs, [
      :change_type,
      :payload,
      :original_record_id,
      :submitted_by_ip,
      :status,
      :approval_token,
      :rejection_token,
      :reviewed_at,
      :reviewer_note
    ])
    |> validate_required([:change_type, :payload, :approval_token, :rejection_token])
    |> validate_inclusion(:change_type, @valid_change_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> unique_constraint(:approval_token)
    |> unique_constraint(:rejection_token)
  end

  @doc """
  Returns the list of valid change types.
  """
  def valid_change_types, do: @valid_change_types

  @doc """
  Returns the list of valid statuses.
  """
  def valid_statuses, do: @valid_statuses
end
