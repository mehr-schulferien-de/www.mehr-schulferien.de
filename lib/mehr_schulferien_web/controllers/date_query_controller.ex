defmodule MehrSchulferienWeb.DateQueryController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{DateQuery, Locations}
  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Is today a public holiday in a federal state?
  Path: /ist-heute-feiertag/:federal_state_slug
  """
  def is_today_public_holiday(conn, %{"federal_state_slug" => state_slug}) do
    with {:ok, federal_state} <- get_federal_state(state_slug) do
      today = DateHelpers.today_berlin()
      result = DateQuery.check_date_status(federal_state, today)

      conn
      |> assign(:result, result)
      |> assign(:federal_state, federal_state)
      |> assign(:query_type, :public_holiday)
      |> assign(:page_title, "Ist heute ein Feiertag in #{federal_state.name}?")
      |> render(:is_today_public_holiday)
    else
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
    with {:ok, federal_state} <- get_federal_state(state_slug) do
      today = DateHelpers.today_berlin()
      result = DateQuery.check_date_status(federal_state, today)

      conn
      |> assign(:result, result)
      |> assign(:federal_state, federal_state)
      |> assign(:query_type, :school_free)
      |> assign(:page_title, "Ist heute schulfrei in #{federal_state.name}?")
      |> render(:is_today_school_free)
    else
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

  defp get_federal_state(slug) do
    case Locations.get_federal_state_by_slug(slug) do
      nil -> {:error, :not_found}
      federal_state -> {:ok, federal_state}
    end
  end

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
