defmodule MehrSchulferien.Ads do
  @moduledoc """
  The Ads context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Ads.TravelOffer

  @doc """
  Returns the list of travel_offers.

  ## Examples

      iex> list_travel_offers()
      [%TravelOffer{}, ...]

  """
  def list_travel_offers do
    Repo.all(TravelOffer)
  end

  @doc """
  Gets a single travel_offer.

  Raises `Ecto.NoResultsError` if the Travel offer does not exist.

  ## Examples

      iex> get_travel_offer!(123)
      %TravelOffer{}

      iex> get_travel_offer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_travel_offer!(id), do: Repo.get!(TravelOffer, id)

  @doc """
  Creates a travel_offer.

  ## Examples

      iex> create_travel_offer(%{field: value})
      {:ok, %TravelOffer{}}

      iex> create_travel_offer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_travel_offer(attrs \\ %{}) do
    %TravelOffer{}
    |> TravelOffer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a travel_offer.

  ## Examples

      iex> update_travel_offer(travel_offer, %{field: new_value})
      {:ok, %TravelOffer{}}

      iex> update_travel_offer(travel_offer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_travel_offer(%TravelOffer{} = travel_offer, attrs) do
    travel_offer
    |> TravelOffer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a TravelOffer.

  ## Examples

      iex> delete_travel_offer(travel_offer)
      {:ok, %TravelOffer{}}

      iex> delete_travel_offer(travel_offer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_travel_offer(%TravelOffer{} = travel_offer) do
    Repo.delete(travel_offer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking travel_offer changes.

  ## Examples

      iex> change_travel_offer(travel_offer)
      %Ecto.Changeset{source: %TravelOffer{}}

  """
  def change_travel_offer(%TravelOffer{} = travel_offer) do
    TravelOffer.changeset(travel_offer, %{})
  end

  alias MehrSchulferien.Ads.Request

  @doc """
  Returns the list of requests.

  ## Examples

      iex> list_requests()
      [%Request{}, ...]

  """
  def list_requests do
    Repo.all(Request)
  end

  @doc """
  Gets a single request.

  Raises `Ecto.NoResultsError` if the Request does not exist.

  ## Examples

      iex> get_request!(123)
      %Request{}

      iex> get_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_request!(id), do: Repo.get!(Request, id)

  @doc """
  Creates a request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(attrs \\ %{}) do
    %Request{}
    |> Request.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a request.

  ## Examples

      iex> update_request(request, %{field: new_value})
      {:ok, %Request{}}

      iex> update_request(request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_request(%Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Request.

  ## Examples

      iex> delete_request(request)
      {:ok, %Request{}}

      iex> delete_request(request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking request changes.

  ## Examples

      iex> change_request(request)
      %Ecto.Changeset{source: %Request{}}

  """
  def change_request(%Request{} = request) do
    Request.changeset(request, %{})
  end
end
