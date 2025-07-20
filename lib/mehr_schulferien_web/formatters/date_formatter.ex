defmodule MehrSchulferienWeb.Formatters.DateFormatter do
  @moduledoc """
  Centralized date formatting functions for the application.

  This module provides consistent date formatting across the application,
  supporting various formats commonly used in German date representations.
  """

  @doc """
  Formats a date in short format (DD.MM.)

  ## Examples

      iex> format_date_short(~D[2024-01-15])
      "15.01."
      
      iex> format_date_short(nil)
      ""
  """
  def format_date_short(nil), do: ""

  def format_date_short(date) do
    Calendar.strftime(date, "%d.%m.")
  end

  @doc """
  Formats a date in full format (DD.MM.YYYY)

  ## Examples

      iex> format_date_full(~D[2024-01-15])
      "15.01.2024"
      
      iex> format_date_full(nil)
      ""
  """
  def format_date_full(nil), do: ""

  def format_date_full(date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

  @doc """
  Formats a date with short year (DD.MM.YY)

  ## Examples

      iex> format_date_with_short_year(~D[2024-01-15])
      "15.01.24"
  """
  def format_date_with_short_year(date) do
    format_date_short(date) <> String.slice(Integer.to_string(date.year), 2, 2)
  end

  @doc """
  Formats a datetime in German format with time

  ## Examples

      iex> format_datetime(~U[2024-01-15 14:30:00Z])
      "15.01.2024 15:30:00 Uhr"
  """
  def format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y %H:%M:%S Uhr")
  end

  def format_datetime(%NaiveDateTime{} = naive_datetime) do
    # Convert NaiveDateTime to DateTime assuming UTC, then shift to Berlin timezone
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y %H:%M:%S Uhr")
  end

  @doc """
  Formats a date range with appropriate separators

  ## Examples

      iex> format_date_range(~D[2024-01-15], ~D[2024-01-20])
      "15.01. - 20.01.24"
      
      iex> format_date_range(~D[2024-01-15], ~D[2024-01-15])
      "15.01.24"
      
      iex> format_date_range(~D[2023-12-20], ~D[2024-01-10])
      "20.12.23 - 10.01.24"
  """
  def format_date_range(same_date, same_date, :short) do
    format_date_short(same_date)
  end

  def format_date_range(same_date, same_date, _) do
    format_date_with_short_year(same_date)
  end

  def format_date_range(from_date, till_date, :short) do
    format_date_short(from_date) <> " - " <> format_date_short(till_date)
  end

  def format_date_range(from_date, till_date, _) do
    from_date_string =
      if from_date.year == till_date.year do
        format_date_short(from_date)
      else
        format_date_with_short_year(from_date)
      end

    from_date_string <> " - " <> format_date_with_short_year(till_date)
  end

  @doc """
  Formats a date for iCal format (YYYYMMDD)

  ## Examples

      iex> format_date_ical(~D[2024-01-15])
      "20240115"
  """
  def format_date_ical(date) do
    "#{date.year}#{pad_number(date.month)}#{pad_number(date.day)}"
  end

  @doc """
  Formats the next day after a date for iCal format

  ## Examples

      iex> format_next_day_ical(~D[2024-01-15])
      "20240116"
  """
  def format_next_day_ical(date) do
    date
    |> Date.add(1)
    |> format_date_ical()
  end

  # Private helper functions

  defp pad_number(number) when number < 10, do: "0#{number}"
  defp pad_number(number), do: "#{number}"
end
