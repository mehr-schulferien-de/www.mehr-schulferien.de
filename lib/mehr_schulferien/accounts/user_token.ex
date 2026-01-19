defmodule MehrSchulferien.Accounts.UserToken do
  @moduledoc """
  Schema for user authentication tokens.

  Supports two contexts:
  - "login": Magic link tokens sent via email (15 min expiry)
  - "session": Browser session tokens (24 hour expiry)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @login_token_validity_minutes 15
  @session_token_validity_hours 24

  schema "user_tokens" do
    field :token_hash, :binary
    field :context, :string
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime
    field :ip_address, :string

    belongs_to :user, MehrSchulferien.Accounts.User

    timestamps()
  end

  @doc """
  Generates a secure random token and returns both the raw token and its hash.

  Returns `{raw_token, token_hash}`.
  """
  def generate_token do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = hash_token(raw_token)
    {raw_token, token_hash}
  end

  @doc """
  Hashes a token using SHA-256.
  """
  def hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  @doc """
  Returns the login token validity duration in minutes.
  """
  def login_token_validity_minutes, do: @login_token_validity_minutes

  @doc """
  Returns the session token validity duration in hours.
  """
  def session_token_validity_hours, do: @session_token_validity_hours

  @doc """
  Changeset for creating a login token (magic link).
  """
  def login_token_changeset(attrs) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@login_token_validity_minutes * 60, :second)
      |> DateTime.truncate(:second)

    %__MODULE__{}
    |> cast(attrs, [:user_id, :token_hash, :ip_address])
    |> validate_required([:user_id, :token_hash])
    |> put_change(:context, "login")
    |> put_change(:expires_at, expires_at)
  end

  @doc """
  Changeset for creating a session token.
  """
  def session_token_changeset(attrs) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@session_token_validity_hours * 60 * 60, :second)
      |> DateTime.truncate(:second)

    %__MODULE__{}
    |> cast(attrs, [:user_id, :token_hash, :ip_address])
    |> validate_required([:user_id, :token_hash])
    |> put_change(:context, "session")
    |> put_change(:expires_at, expires_at)
  end

  @doc """
  Changeset for marking a token as used.
  """
  def mark_used_changeset(token) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(token, used_at: now)
  end

  @doc """
  Checks if the token has expired.
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Checks if the token has been used.
  """
  def used?(%__MODULE__{used_at: nil}), do: false
  def used?(%__MODULE__{used_at: _}), do: true

  @doc """
  Checks if the token is valid (not expired and not used).
  """
  def valid?(%__MODULE__{} = token) do
    not expired?(token) and not used?(token)
  end
end
