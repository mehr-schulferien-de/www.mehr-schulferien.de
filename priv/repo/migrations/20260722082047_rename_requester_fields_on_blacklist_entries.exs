defmodule MehrSchulferien.Repo.Migrations.RenameRequesterFieldsOnBlacklistEntries do
  use Ecto.Migration

  # Align the person columns on blacklist_entries with the naming already used by
  # users and blacklist_verification_requests, so that a person's name and mail
  # address are called full_name/email everywhere in the application.
  def change do
    rename table(:blacklist_entries), :requester_name, to: :full_name
    rename table(:blacklist_entries), :requester_email, to: :email
  end
end
