defmodule MehrSchulferienWeb.Live.Shared.BriefeHelpers do
  @moduledoc """
  Shared helper functions for Briefe (letters) LiveViews.
  Reduces duplication across EntschuldigungLive, BeurlaubungLive, and SportbefreiungLive.
  """

  alias MehrSchulferien.Locations

  @doc """
  Common mount logic for fetching school and location hierarchy.
  """
  def fetch_school_data(school_slug) do
    school = Locations.get_school_by_slug!(school_slug)
    city = Locations.get_location!(school.parent_location_id)
    county = Locations.get_location!(city.parent_location_id)
    federal_state = Locations.get_location!(county.parent_location_id)
    country = Locations.get_location!(federal_state.parent_location_id)

    %{
      school: school,
      city: city,
      county: county,
      federal_state: federal_state,
      country: country
    }
  end

  @doc """
  Sets up the locale from params, session, or socket assigns.
  """
  def setup_locale(params, session, socket) do
    locale = params["locale"] || Map.get(session, "locale") || socket.assigns[:locale] || "de"
    Gettext.put_locale(MehrSchulferienWeb.Gettext, locale)
    locale
  end

  @doc """
  Converts string keys to atoms in a map.
  """
  def atomize_keys(params) do
    Enum.into(params, %{}, fn {k, v} -> {String.to_atom(k), v} end)
  end

  @doc """
  Parses date fields in form data.
  """
  def maybe_parse_dates(form_data, date_fields) do
    Enum.reduce(date_fields, form_data, fn field, acc ->
      parse_date_field(acc, field)
    end)
  end

  defp parse_date_field(form_data, field) do
    case Map.get(form_data, field) do
      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> Map.put(form_data, field, date)
          {:error, _} -> form_data
        end

      _ ->
        form_data
    end
  end

  @doc """
  Validates required fields in form data.
  """
  def validate_form_data(form_data, required_fields) do
    missing_fields =
      required_fields
      |> Enum.filter(fn {field, _label} ->
        value = Map.get(form_data, field)
        is_nil(value) or value == ""
      end)
      |> Enum.map(fn {_field, label} -> label end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Bitte füllen Sie alle Pflichtfelder aus: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  @doc """
  Builds PDF download URL with form data as query parameters.
  """
  def build_pdf_url(school_slug, form_data, document_type) do
    query_params =
      form_data
      |> Map.new(fn {key, value} ->
        {to_string(key), format_param_value(value)}
      end)
      |> URI.encode_query()

    "/briefe/#{school_slug}/#{document_type}/pdf?#{query_params}"
  end

  defp format_param_value(%Date{} = date), do: Date.to_iso8601(date)
  defp format_param_value(true), do: "true"
  defp format_param_value(false), do: "false"
  defp format_param_value(value) when is_binary(value), do: value
  defp format_param_value(value), do: to_string(value)

  @doc """
  Handles locale change events from LanguageSwitcherComponent.
  """
  def handle_locale_change(socket, locale, document_type) do
    Gettext.put_locale(MehrSchulferienWeb.Gettext, locale)
    school_slug = socket.assigns.school.slug

    socket
    |> Phoenix.Component.assign(locale: locale)
    |> Phoenix.LiveView.push_navigate(
      to: "/briefe/#{school_slug}/#{document_type}?locale=#{locale}"
    )
  end

  @doc """
  Success flash message for PDF generation.
  """
  def pdf_success_message do
    "PDF wurde erfolgreich erstellt. Sie können das Formular erneut ausfüllen oder die Daten anpassen."
  end
end
