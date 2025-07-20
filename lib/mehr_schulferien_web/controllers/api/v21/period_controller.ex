defmodule MehrSchulferienWeb.Api.V21.PeriodController do
  @moduledoc """
  API v2.1 controller for periods.

  Provides endpoints for:
  - Listing all periods with filtering options
  - Getting a specific period by ID
  """
  use MehrSchulferienWeb.Api.V21.BaseController

  alias MehrSchulferien.Periods.Period

  def index(conn, params) do
    pagination = parse_pagination(params)
    {start_date, end_date} = parse_date_range(params)

    query = build_index_query(params, start_date, end_date)
    result = paginate(query, pagination.page, pagination.per_page)

    periods =
      result.entries
      |> Repo.preload([:holiday_or_vacation_type, :location])
      |> Enum.map(&format_period_detailed/1)

    render_paginated(conn, periods, %{
      page: result.page,
      per_page: result.per_page,
      total_pages: result.total_pages,
      total_entries: result.total_entries,
      filters: %{
        start_date: start_date,
        end_date: end_date,
        location_id: params["location_id"],
        type: params["type"]
      }
    })
  end

  def show(conn, %{"id" => id}) do
    with {:ok, period} <- get_period_by_id(id) do
      period = Repo.preload(period, [:holiday_or_vacation_type, :location])
      render_json(conn, format_period_detailed(period))
    end
  end

  # Private functions

  defp build_index_query(params, start_date, end_date) do
    query =
      from p in Period,
        where: p.ends_on >= ^start_date and p.starts_on <= ^end_date,
        order_by: [asc: p.starts_on]

    query =
      case params["location_id"] do
        nil ->
          query

        location_id ->
          # Get all location IDs in the hierarchy
          location = Locations.get_location!(location_id)
          location_ids = Locations.recursive_location_ids(location)
          from p in query, where: p.location_id in ^location_ids
      end

    case params["type"] do
      "vacation" ->
        from p in query, where: p.is_school_vacation == true

      "holiday" ->
        from p in query, where: p.is_public_holiday == true

      _ ->
        query
    end
  end

  defp get_period_by_id(id) do
    case Repo.get(Period, id) do
      nil -> {:error, :not_found}
      period -> {:ok, period}
    end
  end

  defp format_period_detailed(period) do
    %{
      id: period.id,
      starts_on: period.starts_on,
      ends_on: period.ends_on,
      name: period.holiday_or_vacation_type.name,
      type: get_period_type(period),
      is_school_vacation: period.is_school_vacation,
      is_public_holiday: period.is_public_holiday,
      is_valid_for_students: period.is_valid_for_students,
      is_valid_for_everybody: period.is_valid_for_everybody,
      display_priority: period.display_priority,
      html_class: period.html_class,
      location: format_location(period.location),
      holiday_or_vacation_type: %{
        id: period.holiday_or_vacation_type.id,
        name: period.holiday_or_vacation_type.name,
        slug: period.holiday_or_vacation_type.slug,
        colloquial: period.holiday_or_vacation_type.colloquial
      }
    }
  end

  defp get_period_type(period) do
    cond do
      period.is_school_vacation -> "school_vacation"
      period.is_public_holiday -> "public_holiday"
      true -> "other"
    end
  end
end
