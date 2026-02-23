defmodule MehrSchulferienWeb.DateQueryController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.DateQuery
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @doc """
  Is today a public holiday in a federal state?
  Path: /ist-heute-feiertag/:federal_state_slug
  """
  def is_today_public_holiday(conn, %{"federal_state_slug" => state_slug}) do
    case get_federal_state(state_slug) do
      {:ok, federal_state} ->
        today = DateHelpers.today_berlin()
        result = DateQuery.check_date_status(federal_state, today)

        conn
        |> assign(:result, result)
        |> assign(:federal_state, federal_state)
        |> assign(:query_type, :public_holiday)
        |> assign(:page_title, "Ist heute ein Feiertag in #{federal_state.name}?")
        |> render(:is_today_public_holiday)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  @doc """
  Is today off school in a federal state?
  Path: /ist-heute-schulfrei/:federal_state_slug
  """
  def is_today_school_free(conn, %{"federal_state_slug" => state_slug}) do
    case get_federal_state(state_slug) do
      {:ok, federal_state} ->
        today = DateHelpers.today_berlin()
        result = DateQuery.check_date_status(federal_state, today)

        conn
        |> assign(:result, result)
        |> assign(:federal_state, federal_state)
        |> assign(:query_type, :school_free)
        |> assign(:page_title, "Ist heute schulfrei in #{federal_state.name}?")
        |> render(:is_today_school_free)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  @doc """
  Is there school on the next Monday in a federal state?
  Path: /ist-am-montag-schule/:federal_state_slug
  """
  def is_monday_school(conn, %{"federal_state_slug" => state_slug}) do
    is_weekday_school(conn, state_slug, 1, "Montag")
  end

  @doc """
  Is there school on the next Friday in a federal state?
  Path: /ist-am-freitag-schule/:federal_state_slug
  """
  def is_friday_school(conn, %{"federal_state_slug" => state_slug}) do
    is_weekday_school(conn, state_slug, 5, "Freitag")
  end

  # Private helper for weekday school queries
  defp is_weekday_school(conn, state_slug, day_of_week, weekday_name) do
    case get_federal_state(state_slug) do
      {:ok, federal_state} ->
        today = DateHelpers.today_berlin()
        target_date = DateHelpers.next_weekday(day_of_week, today)
        is_today = Date.compare(target_date, today) == :eq
        result = DateQuery.check_date_status(federal_state, target_date)

        conn
        |> assign(:result, result)
        |> assign(:federal_state, federal_state)
        |> assign(:weekday_name, weekday_name)
        |> assign(:is_today, is_today)
        |> assign(:query_type, :weekday_school)
        |> assign(:page_title, "Ist am #{weekday_name} Schule in #{federal_state.name}?")
        |> render(:is_weekday_school)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  @doc """
  Is a specific date a school day in a federal state?
  Path: /ist-schultag/:federal_state_slug/:date
  """
  def is_school_day(conn, %{"federal_state_slug" => state_slug, "date" => date_str}) do
    with {:ok, federal_state} <- get_federal_state(state_slug),
         {:ok, date} <- parse_date(date_str) do
      result = DateQuery.check_date_status(federal_state, date)

      conn
      |> assign(:result, result)
      |> assign(:federal_state, federal_state)
      |> assign(:query_type, :school_day)
      |> assign(:page_title, "Ist #{format_date(date)} ein Schultag in #{federal_state.name}?")
      |> render(:is_school_day)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"404")

      {:error, :invalid_date} ->
        conn
        |> put_status(:bad_request)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"400")
    end
  end

  @doc """
  Is a specific date a public holiday in a federal state?
  Path: /ist-feiertag/:federal_state_slug/:date
  """
  def is_public_holiday(conn, %{"federal_state_slug" => state_slug, "date" => date_str}) do
    with {:ok, federal_state} <- get_federal_state(state_slug),
         {:ok, date} <- parse_date(date_str) do
      result = DateQuery.check_date_status(federal_state, date)

      conn
      |> assign(:result, result)
      |> assign(:federal_state, federal_state)
      |> assign(:query_type, :public_holiday)
      |> assign(:page_title, "Ist #{format_date(date)} ein Feiertag in #{federal_state.name}?")
      |> render(:is_public_holiday)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"404")

      {:error, :invalid_date} ->
        conn
        |> put_status(:bad_request)
        |> put_view(MehrSchulferienWeb.ErrorHTML)
        |> render(:"400")
    end
  end

  # Private helpers

  defp get_federal_state(slug), do: CH.fetch_federal_state(slug)

  defp parse_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, :invalid_date}
    end
  end

  defp format_date(date) do
    months = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    ]

    month_name = Enum.at(months, date.month - 1)
    "#{date.day}. #{month_name} #{date.year}"
  end
end
