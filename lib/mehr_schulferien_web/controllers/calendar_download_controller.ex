defmodule MehrSchulferienWeb.CalendarDownloadController do
  @moduledoc """
  Printable year calendars: the download page of a federal state and the PDF
  files of states and schools.

  The PDFs are files in `MehrSchulferien.CalendarPdf.Store`. A request only
  runs pdflatex when its file is missing, and only for the years the calendar
  is offered for, so the set a crawler can make us generate stays bounded.
  """

  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{CalendarPdf, Locations}
  alias MehrSchulferien.Calendars.DateHelpers

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, year} <- parse_year(year),
         {:ok, scope} <- federal_state_scope(country_slug, federal_state_slug) do
      {:federal_state, %{country: country, federal_state: federal_state}} = scope
      years = CalendarPdf.years(scope, today)

      cond do
        year < today.year ->
          # Same consolidation as the past year pages of the state.
          conn
          |> put_status(:moved_permanently)
          |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state.slug}")

        year in years ->
          render(conn, "show.html",
            country: country,
            federal_state: federal_state,
            year: year,
            years: years
          )

        true ->
          not_found(conn)
      end
    else
      _ -> not_found(conn)
    end
  end

  def federal_state_pdf(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year,
        "file" => file
      }) do
    case federal_state_scope(country_slug, federal_state_slug) do
      {:ok, scope} -> send_pdf(conn, scope, year, file, "schulferien-#{federal_state_slug}")
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  def school_pdf(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year,
        "file" => file
      }) do
    with {:ok, locations} <- Locations.show_school_to_country_map_safe(country_slug, school_slug),
         false <- Locations.school_quarantined?(locations.school) do
      send_pdf(conn, {:school, locations}, year, file, "schulferien-#{school_slug}")
    else
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  defp send_pdf(conn, scope, year, file, name) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, year} <- parse_year(year),
         {:ok, format} <- parse_file(file),
         true <- CalendarPdf.offered_year?(year, today),
         {:ok, path} <- CalendarPdf.fetch(scope, year, format) do
      conn
      |> put_resp_content_type("application/pdf", nil)
      |> put_resp_header(
        "content-disposition",
        ~s(inline; filename="#{name}-#{year}-#{format}.pdf")
      )
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> send_file(200, path)
    else
      {:error, :busy} -> unavailable(conn, 60)
      {:error, reason} when reason not in [:no_data, :unknown_format] -> unavailable(conn, 300)
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  defp unavailable(conn, retry_after) do
    conn
    |> put_resp_header("retry-after", Integer.to_string(retry_after))
    |> send_resp(
      :service_unavailable,
      "Der Kalender wird gerade erzeugt. Bitte gleich noch einmal versuchen."
    )
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(MehrSchulferienWeb.ErrorHTML)
    |> render("404.html")
  end

  defp federal_state_scope(country_slug, federal_state_slug) do
    with {:ok, {federal_state, country}} <-
           Locations.get_federal_state_and_country_by_slug(country_slug, federal_state_slug) do
      {:ok, {:federal_state, %{country: country, federal_state: federal_state}}}
    end
  end

  defp parse_year(year) do
    case Integer.parse(year) do
      {year, ""} -> {:ok, year}
      _ -> :error
    end
  end

  defp parse_file(file) do
    with [format, "pdf"] <- String.split(file, "."),
         true <- format in CalendarPdf.formats() do
      {:ok, format}
    else
      _ -> :error
    end
  end
end
