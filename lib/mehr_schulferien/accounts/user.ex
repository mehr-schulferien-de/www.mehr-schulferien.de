defmodule MehrSchulferien.Accounts.User do
  @moduledoc """
  Schema for wiki users.

  Users authenticate via magic links (passwordless). They may be banned
  to prevent further wiki edits.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :full_name, :string
    field :confirmed_at, :utc_datetime
    field :banned_at, :utc_datetime
    field :ban_reason, :string

    has_many :tokens, MehrSchulferien.Accounts.UserToken

    timestamps()
  end

  @doc """
  Changeset for creating a new user.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :full_name])
    |> validate_required([:email, :full_name])
    |> validate_length(:full_name, min: 2, message: "muss mindestens 2 Zeichen haben")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "muss eine gültige E-Mail-Adresse sein"
    )
    |> normalize_email()
    |> unique_constraint(:email, name: :users_email_index)
  end

  @doc """
  Changeset for updating a user's full name.
  """
  def update_full_name_changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name])
    |> validate_required([:full_name])
    |> validate_length(:full_name, min: 2, message: "muss mindestens 2 Zeichen haben")
  end

  @doc """
  Changeset for confirming a user's email.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Changeset for banning a user.
  """
  def ban_changeset(user, reason) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, banned_at: now, ban_reason: reason)
  end

  @doc """
  Changeset for unbanning a user.
  """
  def unban_changeset(user) do
    change(user, banned_at: nil, ban_reason: nil)
  end

  @doc """
  Checks if a user is banned.
  """
  def banned?(%__MODULE__{banned_at: nil}), do: false
  def banned?(%__MODULE__{banned_at: _}), do: true

  @doc """
  Checks if a user is confirmed.
  """
  def confirmed?(%__MODULE__{confirmed_at: nil}), do: false
  def confirmed?(%__MODULE__{confirmed_at: _}), do: true

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(String.trim(email)))
    end
  end
end
