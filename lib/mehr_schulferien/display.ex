defmodule MehrSchulferien.Display do
  @moduledoc """
  The Display context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Display.FederalState

  @doc """
  Returns the list of federal_states.

  ## Examples

      iex> list_federal_states()
      [%FederalState{}, ...]

  """
  def list_federal_states do
    Repo.all(FederalState)
  end

  @doc """
  Gets a single federal_state.

  Raises `Ecto.NoResultsError` if the Federal state does not exist.

  ## Examples

      iex> get_federal_state!(123)
      %FederalState{}

      iex> get_federal_state!(456)
      ** (Ecto.NoResultsError)

  """
  def get_federal_state!(id), do: Repo.get!(FederalState, id)

  @doc """
  Creates a federal_state.

  ## Examples

      iex> create_federal_state(%{field: value})
      {:ok, %FederalState{}}

      iex> create_federal_state(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_federal_state(attrs \\ %{}) do
    %FederalState{}
    |> FederalState.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a federal_state.

  ## Examples

      iex> update_federal_state(federal_state, %{field: new_value})
      {:ok, %FederalState{}}

      iex> update_federal_state(federal_state, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_federal_state(%FederalState{} = federal_state, attrs) do
    federal_state
    |> FederalState.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a federal_state.

  ## Examples

      iex> delete_federal_state(federal_state)
      {:ok, %FederalState{}}

      iex> delete_federal_state(federal_state)
      {:error, %Ecto.Changeset{}}

  """
  def delete_federal_state(%FederalState{} = federal_state) do
    Repo.delete(federal_state)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking federal_state changes.

  ## Examples

      iex> change_federal_state(federal_state)
      %Ecto.Changeset{source: %FederalState{}}

  """
  def change_federal_state(%FederalState{} = federal_state) do
    FederalState.changeset(federal_state, %{})
  end
end
