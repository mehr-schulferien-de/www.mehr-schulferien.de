defmodule MehrSchulferien.Calendars.ReligionOperations do
  @moduledoc """
  Operations on religions.

  This module handles all operations related to religions in the calendars context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.Religion
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of religions.
  """
  def list_religions do
    Repo.all(Religion)
  end

  @doc """
  Gets a single religion.

  Raises `Ecto.NoResultsError` if the Religion does not exist.
  """
  def get_religion!(id), do: Repo.get!(Religion, id)

  @doc """
  Creates a religion.
  """
  def create_religion(attrs \\ %{}) do
    %Religion{}
    |> Religion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a religion.
  """
  def update_religion(%Religion{} = religion, attrs) do
    religion
    |> Religion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a religion.
  """
  def delete_religion(%Religion{} = religion) do
    Repo.delete(religion)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking religion changes.
  """
  def change_religion(%Religion{} = religion) do
    Religion.changeset(religion, %{})
  end
end
