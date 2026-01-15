defmodule MehrSchulferien.Blacklist.VerificationRequest do
  @moduledoc """
  Schema for blacklist verification requests.

  When a user wants to create a blacklist entry, they must first verify their
  email address via a magic link. This schema stores the verification request
  including the hashed token, expiration time, and verification status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @token_validity_hours 24

  schema "blacklist_verification_requests" do
    field :full_name, :string
    field :email, :string
    field :token_hash, :string
    field :verified_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :ip_address, :string
    field :user_agent, :string

    has_many :entries, MehrSchulferien.Blacklist.Entry, foreign_key: :verification_request_id

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
    :crypto.hash(:sha256, token) |> Base.encode64()
  end

  @doc """
  Returns the token validity duration in hours.
  """
  def token_validity_hours, do: @token_validity_hours

  @doc false
  def changeset(verification_request, attrs) do
    verification_request
    |> cast(attrs, [
      :full_name,
      :email,
      :token_hash,
      :verified_at,
      :expires_at,
      :ip_address,
      :user_agent
    ])
    |> validate_required([:full_name, :email, :token_hash, :expires_at])
    |> validate_length(:full_name, min: 2, max: 200)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "muss eine gültige E-Mail-Adresse sein"
    )
    |> normalize_email()
  end

  @doc """
  Changeset for creating a new verification request.
  """
  def create_changeset(attrs) do
    attrs_with_expiration = Map.put(attrs, :expires_at, default_expiration())

    %__MODULE__{}
    |> changeset(attrs_with_expiration)
  end

  @doc """
  Changeset for marking a request as verified.
  """
  def verify_changeset(verification_request) do
    verification_request
    |> change()
    |> put_change(:verified_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Checks if the verification request has expired.
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Checks if the verification request has been verified.
  """
  def verified?(%__MODULE__{verified_at: nil}), do: false
  def verified?(%__MODULE__{verified_at: _}), do: true

  defp default_expiration do
    DateTime.utc_now()
    |> DateTime.add(@token_validity_hours * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(String.trim(email)))
    end
  end
end
