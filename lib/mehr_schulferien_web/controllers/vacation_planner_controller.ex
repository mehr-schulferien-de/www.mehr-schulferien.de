defmodule MehrSchulferienWeb.VacationPlannerController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods, VacationOptimization}
  alias MehrSchulferien.VacationOptimization.Optimizer
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @doc """
  Redirects to the current year for normal variant.
  """
  def index(conn, %{"federal_state_slug" => federal_state_slug, "days" => days}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    conn
    |> redirect(
      to: ~p"/urlaubsplaner/#{federal_state_slug}/#{days}/#{current_year}",
      status: :temporary_redirect
    )
  end

  @doc """
  Redirects to the current year for budget variant.
  """
  def index_budget(conn, %{"federal_state_slug" => federal_state_slug, "days" => days}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    conn
    |> redirect(
      to: ~p"/urlaubsplaner-guenstig/#{federal_state_slug}/#{days}/#{current_year}",
      status: :temporary_redirect
    )
  end

  @doc """
  Shows vacation optimization results for normal variant.
  """
  def show(conn, params) do
    render_vacation_planner(conn, params, :normal)
  end

  @doc """
  Shows vacation optimization results for budget variant (avoids school vacations).
  """
  def show_budget(conn, params) do
    render_vacation_planner(conn, params, :budget)
  end

  defp render_vacation_planner(
         conn,
         %{
           "federal_state_slug" => federal_state_slug,
           "days" => days_param,
           "year" => year_param
         },
         variant
       ) do
    with {:ok, days} <- parse_days(days_param),
         {:ok, year} <- check_year(year_param),
         {:ok, federal_state} <- get_federal_state(federal_state_slug),
         {:ok, country} <- get_country(federal_state) do
      location_ids = Locations.recursive_location_ids(federal_state)

      # Request more candidates (top: 30) so we have enough to find 3 distinct results
      # The distinct filter will reduce this to 3 non-overlapping results
      opts =
        if variant == :budget do
          [avoid_school_vacations: true, top: 30]
        else
          [avoid_school_vacations: false, top: 30]
        end

      optimal_windows = VacationOptimization.find_optimal_windows(location_ids, year, days, opts)

      all_federal_states = Locations.list_federal_states(country)

      # Fetch public periods for calendar display (extended range for cross-year)
      year_start = Date.new!(year, 1, 1)
      # Extended range to cover cross-year window (Dec previous to Feb next)
      extended_start = Date.add(year_start, -15)
      extended_end = Date.new!(year + 1, 2, 28)
      public_periods = Periods.list_public_periods(location_ids, extended_start, extended_end)

      # Fetch school vacation periods for calendar display (to show overlap in budget variant)
      school_vacation_periods =
        Periods.list_school_vacation_periods(location_ids, extended_start, extended_end)

      # Filter to distinct results and compute vacation dates for each
      distinct_results = Optimizer.filter_distinct_results(optimal_windows, max_results: 3)

      distinct_results_with_dates =
        Enum.map(distinct_results, fn result ->
          vacation_dates = Optimizer.compute_vacation_dates(result, public_periods)
          Map.put(result, :vacation_dates, vacation_dates)
        end)

      # SEO-friendly page title
      page_title =
        if variant == :budget do
          "#{days} Urlaubstage #{year} in #{federal_state.name} optimal planen – Günstig reisen"
        else
          "#{days} Urlaubstage #{year} in #{federal_state.name} optimal planen"
        end

      assigns = [
        country: country,
        federal_state: federal_state,
        year: year,
        days: days,
        variant: variant,
        vc: variant_config(variant),
        optimal_windows: optimal_windows,
        distinct_results: distinct_results_with_dates,
        public_periods: public_periods,
        school_vacation_periods: school_vacation_periods,
        all_federal_states: all_federal_states,
        page_title: page_title,
        # The state x day-count x year combinatorics are tools for humans,
        # not search landing pages: Google leaves them in "crawled -
        # currently not indexed" limbo and they drain the crawl budget.
        noindex: true
      ]

      render(conn, "show.html", assigns)
    else
      {:error, :invalid_days} ->
        raise_not_found(conn)

      {:error, :invalid_year} ->
        raise_not_found(conn)

      {:error, :not_found} ->
        raise_not_found(conn)

      _ ->
        raise_not_found(conn)
    end
  end

  # Variant configuration for the shared show.html template.
  #
  # Tailwind classes are stored as COMPLETE strings (never built from
  # interpolated fragments) so the Tailwind scanner picks them up.
  defp variant_config(:budget) do
    %{
      mode: :budget,
      lead_class: "mt-2 text-green-700 dark:text-green-400",
      tab_normal_class:
        "px-4 py-2 text-sm font-medium rounded-md text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700",
      tab_budget_class:
        "px-4 py-2 text-sm font-medium rounded-md bg-green-600 text-white shadow-sm",
      pill_active_class: "bg-green-600 text-white",
      summary_class: "cursor-pointer text-green-600 dark:text-green-400 hover:underline",
      state_link_class: "text-sm text-green-600 dark:text-green-400 hover:underline",
      info_box_class:
        "bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4"
    }
  end

  defp variant_config(:normal) do
    %{
      mode: :normal,
      lead_class: "mt-2",
      tab_normal_class:
        "px-4 py-2 text-sm font-medium rounded-md bg-blue-600 text-white shadow-sm",
      tab_budget_class:
        "px-4 py-2 text-sm font-medium rounded-md text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700",
      pill_active_class: "bg-blue-600 text-white",
      summary_class: "cursor-pointer text-blue-600 dark:text-blue-400 hover:underline",
      state_link_class: "text-sm text-blue-600 dark:text-blue-400 hover:underline",
      info_box_class:
        "bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4"
    }
  end

  defp parse_days(days_string) do
    case VacationOptimization.parse_days_from_url(days_string) do
      {:ok, days} -> {:ok, days}
      {:error, _} -> {:error, :invalid_days}
    end
  end

  defp check_year(year_string), do: CH.check_year(year_string)

  defp get_federal_state(slug), do: CH.fetch_federal_state(slug)

  defp get_country(federal_state) do
    case Locations.get_location(federal_state.parent_location_id) do
      nil -> {:error, :not_found}
      country -> {:ok, country}
    end
  end

  defp raise_not_found(conn) do
    conn = Plug.Conn.put_status(conn, :not_found)
    raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
  end
end
