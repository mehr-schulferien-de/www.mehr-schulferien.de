defmodule MehrSchulferienWeb.Api.V21.QueryController do
  @moduledoc """
  API v2.1 controller for date queries.

  Provides endpoints for:
  - Checking if a date is a public holiday
  - Checking if a date is a school day
  - Comprehensive date status checks
  """
  use MehrSchulferienWeb.Api.V21.BaseController

  alias MehrSchulferien.{DateQuery, Locations}
  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Check if a date is a public holiday.

  GET /api/v2.1/queries/is-public-holiday?location_slug=bayern&date=2025-12-25

  Query parameters:
  - location_slug (required): Slug of the location (federal state, city, or school)
  - date (optional): Date in ISO format (YYYY-MM-DD), defaults to today
  """
  def is_public_holiday(conn, params) do
    with {:ok, location} <- get_location(params["location_slug"]),
         {:ok, date} <- parse_date_param(params["date"]) do
      {is_holiday, periods} = DateQuery.is_public_holiday?(location, date)

      result = %{
        date: Date.to_iso8601(date),
        location: format_location(location),
        is_public_holiday: is_holiday,
        holidays:
          Enum.map(periods, fn period ->
            %{
              name: period.holiday_or_vacation_type.name,
              starts_on: Date.to_iso8601(period.starts_on),
              ends_on: Date.to_iso8601(period.ends_on)
            }
          end)
      }

      render_json(conn, result)
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :invalid_date} ->
        {:error, :invalid_date}
    end
  end

  @doc """
  Check if a date is a school day.

  GET /api/v2.1/queries/is-school-day?location_slug=bayern&date=2025-09-15

  Query parameters:
  - location_slug (required): Slug of the location (federal state, city, or school)
  - date (optional): Date in ISO format (YYYY-MM-DD), defaults to today
  """
  def is_school_day(conn, params) do
    with {:ok, location} <- get_location(params["location_slug"]),
         {:ok, date} <- parse_date_param(params["date"]) do
      {is_school, periods} = DateQuery.is_school_day?(location, date)

      result = %{
        date: Date.to_iso8601(date),
        location: format_location(location),
        is_school_day: is_school,
        school_free_periods:
          Enum.map(periods, fn period ->
            %{
              name: period.holiday_or_vacation_type.name,
              colloquial: period.holiday_or_vacation_type.colloquial,
              starts_on: Date.to_iso8601(period.starts_on),
              ends_on: Date.to_iso8601(period.ends_on),
              is_vacation: period.is_school_vacation,
              is_holiday: period.is_public_holiday
            }
          end)
      }

      render_json(conn, result)
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :invalid_date} ->
        {:error, :invalid_date}
    end
  end

  @doc """
  Check comprehensive status of a date.

  GET /api/v2.1/queries/check-date?location_slug=bayern&date=2025-12-25

  Query parameters:
  - location_slug (required): Slug of the location (federal state, city, or school)
  - date (optional): Date in ISO format (YYYY-MM-DD), defaults to today
  """
  def check_date(conn, params) do
    with {:ok, location} <- get_location(params["location_slug"]),
         {:ok, date} <- parse_date_param(params["date"]) do
      result = DateQuery.check_date_status(location, date)

      formatted_result = %{
        date: Date.to_iso8601(result.date),
        location: format_location(result.location),
        is_public_holiday: result.is_public_holiday,
        is_school_day: result.is_school_day,
        is_school_vacation: result.is_school_vacation,
        is_weekend: result.is_weekend,
        public_holidays:
          Enum.map(result.public_holiday_periods, fn period ->
            %{
              name: period.holiday_or_vacation_type.name,
              starts_on: Date.to_iso8601(period.starts_on),
              ends_on: Date.to_iso8601(period.ends_on)
            }
          end),
        school_vacations:
          Enum.map(result.school_vacation_periods, fn period ->
            %{
              name: period.holiday_or_vacation_type.name,
              colloquial: period.holiday_or_vacation_type.colloquial,
              starts_on: Date.to_iso8601(period.starts_on),
              ends_on: Date.to_iso8601(period.ends_on)
            }
          end),
        explanation: result.explanation
      }

      render_json(conn, formatted_result)
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :invalid_date} ->
        {:error, :invalid_date}
    end
  end

  # Private helpers

  defp get_location(nil), do: {:error, :not_found}

  defp get_location(slug) do
    try do
      location = Locations.get_location_by_slug!(slug)
      {:ok, location}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  defp parse_date_param(nil), do: {:ok, DateHelpers.today_berlin()}

  defp parse_date_param(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, :invalid_date}
    end
  end

  defp parse_date_param(_), do: {:error, :invalid_date}
end
