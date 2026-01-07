defmodule MehrSchulferienWeb.Api.V21.VacationOptimizerController do
  @moduledoc """
  API v2.1 controller for vacation optimization.

  Provides endpoints for:
  - Getting optimal vacation windows for a federal state
  - Generating iCalendar with optimal vacation periods
  """
  use MehrSchulferienWeb.Api.V21.BaseController

  alias MehrSchulferien.VacationOptimization
  alias MehrSchulferien.VacationOptimization.ICalGenerator

  def show(conn, %{"slug" => slug} = params) do
    with {:ok, federal_state} <- get_federal_state_by_slug(slug),
         {:ok, year} <- parse_year(params["year"]),
         {:ok, days} <- parse_days(params["days"]) do
      variant = if params["variant"] == "budget", do: :budget, else: :normal
      top = param_to_integer(params["top"], 5)

      location_ids = Locations.recursive_location_ids(federal_state)

      opts = [
        avoid_school_vacations: variant == :budget,
        top: top
      ]

      optimal_windows = VacationOptimization.find_optimal_windows(location_ids, year, days, opts)

      cross_year_window =
        VacationOptimization.find_cross_year_window(location_ids, year, days, opts)

      result =
        format_result(optimal_windows, cross_year_window, federal_state, year, days, variant)

      render_json(conn, result)
    else
      {:error, :invalid_year} ->
        {:error,
         "Invalid year parameter. Must be an integer between current year - 5 and current year + 3."}

      {:error, :invalid_days} ->
        {:error, "Invalid days parameter. Must be an integer between 1 and 60."}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def icalendar(conn, %{"slug" => slug} = params) do
    with {:ok, federal_state} <- get_federal_state_by_slug(slug),
         {:ok, year} <- parse_year(params["year"]),
         {:ok, days} <- parse_days(params["days"]) do
      variant = if params["variant"] == "budget", do: :budget, else: :normal
      top = param_to_integer(params["top"], 5)

      location_ids = Locations.recursive_location_ids(federal_state)

      opts = [
        avoid_school_vacations: variant == :budget,
        top: top
      ]

      optimal_windows = VacationOptimization.find_optimal_windows(location_ids, year, days, opts)

      ical_content = ICalGenerator.generate(optimal_windows, federal_state, year, days)

      filename = build_ical_filename(federal_state.name, year, days, variant)

      conn
      |> put_resp_header("content-type", "text/calendar; charset=utf-8")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> text(ical_content)
    else
      {:error, :invalid_year} ->
        {:error,
         "Invalid year parameter. Must be an integer between current year - 5 and current year + 3."}

      {:error, :invalid_days} ->
        {:error, "Invalid days parameter. Must be an integer between 1 and 60."}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp parse_year(nil), do: {:ok, Date.utc_today().year}

  defp parse_year(year_string) when is_binary(year_string) do
    case Integer.parse(year_string) do
      {year, ""} ->
        current_year = Date.utc_today().year

        if year in (current_year - 5)..(current_year + 3) do
          {:ok, year}
        else
          {:error, :invalid_year}
        end

      _ ->
        {:error, :invalid_year}
    end
  end

  defp parse_days(nil), do: {:error, :invalid_days}

  defp parse_days(days_string) when is_binary(days_string) do
    case Integer.parse(days_string) do
      {days, ""} when days >= 1 and days <= 60 -> {:ok, days}
      _ -> {:error, :invalid_days}
    end
  end

  defp get_federal_state_by_slug(slug) do
    query =
      from l in Location,
        where: l.slug == ^slug and l.is_federal_state == true

    case Repo.one(query) do
      nil -> {:error, :not_found}
      federal_state -> {:ok, federal_state}
    end
  end

  defp format_result(optimal_windows, cross_year_window, federal_state, year, days, variant) do
    best = List.first(optimal_windows)

    %{
      location: %{
        id: federal_state.id,
        name: federal_state.name,
        slug: federal_state.slug,
        type: "federal_state"
      },
      year: year,
      vacation_days_requested: days,
      variant: variant,
      summary:
        if best do
          %{
            best_total_free_days: best.total_free_days,
            best_efficiency_percentage: best.efficiency_percentage,
            opportunities_found: length(optimal_windows)
          }
        else
          %{
            best_total_free_days: 0,
            best_efficiency_percentage: 0,
            opportunities_found: 0
          }
        end,
      optimal_windows: Enum.map(optimal_windows, &format_window/1),
      cross_year_option: if(cross_year_window, do: format_window(cross_year_window), else: nil),
      links: %{
        web_page: build_web_url(federal_state.slug, days, year, variant),
        icalendar: build_ical_url(federal_state.slug, days, year, variant)
      }
    }
  end

  defp format_window(window) do
    %{
      rank: window.rank,
      starts_on: window.start_date,
      ends_on: window.end_date,
      vacation_days_used: window.vacation_days_used,
      total_free_days: window.total_free_days,
      breakdown: %{
        vacation_days: window.vacation_days_used,
        weekend_days: window.weekend_days,
        holiday_days: window.holiday_days
      },
      efficiency_percentage: window.efficiency_percentage,
      spans_year_boundary: window.spans_year_boundary,
      includes_school_vacation: window.includes_school_vacation,
      related_holidays: window.related_holidays
    }
  end

  defp build_web_url(slug, days, year, variant) do
    base = Application.get_env(:mehr_schulferien, :base_url, "https://www.mehr-schulferien.de")
    path_prefix = if variant == :budget, do: "urlaubsplaner-guenstig", else: "urlaubsplaner"
    "#{base}/#{path_prefix}/#{slug}/#{days}-tage/#{year}"
  end

  defp build_ical_url(slug, days, year, variant) do
    base = Application.get_env(:mehr_schulferien, :base_url, "https://www.mehr-schulferien.de")
    variant_param = if variant == :budget, do: "&variant=budget", else: ""

    "#{base}/api/v2.1/federal-states/#{slug}/vacation-optimizer/icalendar?year=#{year}&days=#{days}#{variant_param}"
  end

  defp build_ical_filename(name, year, days, variant) do
    variant_suffix = if variant == :budget, do: "-guenstig", else: ""
    sanitized_name = String.replace(name, ~r/[^a-zA-Z0-9äöüÄÖÜß-]/, "_")
    "urlaubsplaner-#{sanitized_name}-#{days}-tage-#{year}#{variant_suffix}.ics"
  end
end
