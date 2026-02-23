defmodule MehrSchulferien.Accounts do
  @moduledoc """
  The Accounts context for wiki user authentication.

  This module provides magic link authentication:
  - Users enter email to receive a login link
  - Login links expire after 15 minutes
  - Sessions last 24 hours
  - No passwords are stored
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Accounts.{User, UserToken}
  alias MehrSchulferien.{Email, Mailer}
  alias MehrSchulferien.Repo

  # ============================================================================
  # User Management
  # ============================================================================

  @doc """
  Gets a user by email (case-insensitive).

  Returns the user or nil.
  """
  def get_user_by_email(email) when is_binary(email) do
    normalized = String.downcase(String.trim(email))

    User
    |> where([u], fragment("lower(?)", u.email) == ^normalized)
    |> Repo.one()
  end

  @doc """
  Gets or creates a user by email.

  Optionally accepts a full_name to store or update the user's name.

  Returns `{:ok, user}` on success.
  Returns `{:error, changeset}` on failure.
  """
  def get_or_create_user_by_email(email, opts \\ []) when is_binary(email) do
    full_name = Keyword.get(opts, :full_name)

    case get_user_by_email(email) do
      nil ->
        %User{}
        |> User.registration_changeset(%{email: email, full_name: full_name})
        |> Repo.insert()

      user ->
        # Update full_name if provided and different
        if full_name && full_name != user.full_name do
          user
          |> User.update_full_name_changeset(%{full_name: full_name})
          |> Repo.update()
        else
          {:ok, user}
        end
    end
  end

  @doc """
  Gets a user by ID.

  Returns the user or nil.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Bans a user with a reason.

  Returns `{:ok, user}` on success.
  """
  def ban_user(%User{} = user, reason) do
    user
    |> User.ban_changeset(reason)
    |> Repo.update()
  end

  @doc """
  Unbans a user.

  Returns `{:ok, user}` on success.
  """
  def unban_user(%User{} = user) do
    user
    |> User.unban_changeset()
    |> Repo.update()
  end

  # ============================================================================
  # Magic Link Authentication
  # ============================================================================

  @doc """
  Creates a login token and sends a magic link email.

  Options:
    - :full_name - the user's full name (required for new users)
    - :ip_address - the IP address of the request

  Returns `{:ok, user}` on success.
  Returns `{:error, reason}` on failure.
  """
  def send_magic_link(email, opts \\ []) do
    full_name = Keyword.get(opts, :full_name)

    with {:ok, user} <- get_or_create_user_by_email(email, full_name: full_name) do
      if User.banned?(user) do
        {:error, :banned}
      else
        {raw_token, token_hash} = UserToken.generate_token()

        token_attrs = %{
          user_id: user.id,
          token_hash: token_hash,
          ip_address: Keyword.get(opts, :ip_address)
        }

        case Repo.insert(UserToken.login_token_changeset(token_attrs)) do
          {:ok, _token} ->
            Email.magic_link_email(user, raw_token)
            |> Mailer.deliver()

            {:ok, user}

          {:error, changeset} ->
            {:error, changeset}
        end
      end
    end
  end

  @doc """
  Verifies a login token and returns the user.

  This also marks the login token as used and confirms the user
  if not already confirmed.

  Returns `{:ok, user}` on success.
  Returns `{:error, reason}` on failure where reason is one of:
    - :not_found
    - :expired
    - :already_used
    - :banned
  """
  def verify_login_token(raw_token) do
    token_hash = UserToken.hash_token(raw_token)

    query =
      from t in UserToken,
        where: t.token_hash == ^token_hash and t.context == "login",
        preload: [:user]

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      token ->
        cond do
          UserToken.expired?(token) ->
            {:error, :expired}

          UserToken.used?(token) ->
            {:error, :already_used}

          User.banned?(token.user) ->
            {:error, :banned}

          true ->
            Repo.transaction(fn ->
              # Mark token as used
              token
              |> UserToken.mark_used_changeset()
              |> Repo.update!()

              # Confirm user if not already confirmed
              user =
                if User.confirmed?(token.user) do
                  token.user
                else
                  token.user
                  |> User.confirm_changeset()
                  |> Repo.update!()
                end

              user
            end)
        end
    end
  end

  # ============================================================================
  # Session Management
  # ============================================================================

  @doc """
  Creates a session token for a user.

  Returns `{raw_token, token}` on success.
  """
  def create_session_token(%User{} = user, opts \\ []) do
    {raw_token, token_hash} = UserToken.generate_token()

    token_attrs = %{
      user_id: user.id,
      token_hash: token_hash,
      ip_address: Keyword.get(opts, :ip_address)
    }

    {:ok, token} = Repo.insert(UserToken.session_token_changeset(token_attrs))
    {raw_token, token}
  end

  @doc """
  Gets a user by session token.

  Returns the user if the token is valid, nil otherwise.
  """
  def get_user_by_session_token(raw_token) when is_binary(raw_token) do
    token_hash = UserToken.hash_token(raw_token)

    query =
      from t in UserToken,
        where: t.token_hash == ^token_hash and t.context == "session",
        preload: [:user]

    case Repo.one(query) do
      nil ->
        nil

      token ->
        if UserToken.valid?(token) and not User.banned?(token.user) do
          token.user
        else
          nil
        end
    end
  end

  @doc """
  Deletes a session token (logout).

  Returns `:ok`.
  """
  def delete_session_token(raw_token) when is_binary(raw_token) do
    token_hash = UserToken.hash_token(raw_token)

    from(t in UserToken, where: t.token_hash == ^token_hash and t.context == "session")
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Deletes all session tokens for a user (logout everywhere).

  Returns `:ok`.
  """
  def delete_all_user_sessions(%User{} = user) do
    from(t in UserToken, where: t.user_id == ^user.id and t.context == "session")
    |> Repo.delete_all()

    :ok
  end

  # ============================================================================
  # Cleanup
  # ============================================================================

  @doc """
  Deletes expired tokens.

  Returns the number of deleted tokens.
  """
  def delete_expired_tokens do
    now = DateTime.utc_now()

    {count, _} =
      from(t in UserToken, where: t.expires_at < ^now)
      |> Repo.delete_all()

    count
  end
end
