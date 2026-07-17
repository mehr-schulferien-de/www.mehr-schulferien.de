defmodule MehrSchulferien.Helpers.DateComparison do
  @moduledoc """
  Common date comparison helpers to avoid duplication across the codebase.
  """

  @doc """
  Checks if first date is after second date.

  ## Examples
      
      iex> is_after?(~D[2024-01-02], ~D[2024-01-01])
      true
      
      iex> is_after?(~D[2024-01-01], ~D[2024-01-02])
      false
  """
  def is_after?(date1, date2) do
    Date.compare(date1, date2) == :gt
  end

  @doc """
  Checks if first date is before second date.

  ## Examples
      
      iex> is_before?(~D[2024-01-01], ~D[2024-01-02])
      true
      
      iex> is_before?(~D[2024-01-02], ~D[2024-01-01])
      false
  """
  def is_before?(date1, date2) do
    Date.compare(date1, date2) == :lt
  end

  @doc """
  Checks if first date is on or after second date.

  ## Examples
      
      iex> is_on_or_after?(~D[2024-01-02], ~D[2024-01-01])
      true
      
      iex> is_on_or_after?(~D[2024-01-01], ~D[2024-01-01])
      true
  """
  def is_on_or_after?(date1, date2) do
    Date.compare(date1, date2) != :lt
  end

  @doc """
  Checks if first date is on or before second date.

  ## Examples
      
      iex> is_on_or_before?(~D[2024-01-01], ~D[2024-01-02])
      true
      
      iex> is_on_or_before?(~D[2024-01-01], ~D[2024-01-01])
      true
  """
  def is_on_or_before?(date1, date2) do
    Date.compare(date1, date2) != :gt
  end

  @doc """
  Checks if a date is between two dates (inclusive).

  ## Examples
      
      iex> is_between?(~D[2024-01-15], ~D[2024-01-01], ~D[2024-01-31])
      true
      
      iex> is_between?(~D[2024-02-01], ~D[2024-01-01], ~D[2024-01-31])
      false
  """
  def is_between?(date, start_date, end_date) do
    is_on_or_after?(date, start_date) && is_on_or_before?(date, end_date)
  end

  @doc """
  Checks if two date ranges overlap.

  ## Examples
      
      iex> ranges_overlap?(~D[2024-01-01], ~D[2024-01-15], ~D[2024-01-10], ~D[2024-01-20])
      true
      
      iex> ranges_overlap?(~D[2024-01-01], ~D[2024-01-10], ~D[2024-01-11], ~D[2024-01-20])
      false
  """
  def ranges_overlap?(start1, end1, start2, end2) do
    is_on_or_before?(start1, end2) && is_on_or_after?(end1, start2)
  end

  @doc """
  Filters a list of items after a given date using a date extractor function.

  ## Examples
      
      iex> periods = [%{starts_on: ~D[2024-01-01]}, %{starts_on: ~D[2024-02-01]}]
      iex> filter_after(periods, ~D[2024-01-15], & &1.starts_on)
      [%{starts_on: ~D[2024-02-01]}]
  """
  def filter_after(list, date, date_fn) do
    Enum.filter(list, fn item -> is_after?(date_fn.(item), date) end)
  end

  @doc """
  Filters a list of items before a given date using a date extractor function.
  """
  def filter_before(list, date, date_fn) do
    Enum.filter(list, fn item -> is_before?(date_fn.(item), date) end)
  end
end
