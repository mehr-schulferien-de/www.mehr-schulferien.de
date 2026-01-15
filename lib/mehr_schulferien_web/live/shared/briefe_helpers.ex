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

  # Known form field keys that can be atomized safely
  @known_form_keys ~w(
    title first_name last_name street zip_code city
    name_of_student class_name duration_type single_date
    start_date end_date teacher_salutation teacher_name
    child_type detailed_reason medical_certificate
    student_name parent_name date reason signature_date
    class school_year sport_type duration excuse_type
    phone email parent_first_name parent_last_name
    student_first_name student_last_name absence_date
    absence_start_date absence_end_date
  )a

  @doc """
  Converts string keys to atoms in a map, only for known keys.
  Unknown keys are silently dropped for security (prevents atom table exhaustion).
  """
  def atomize_keys(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      case safe_to_atom(k) do
        {:ok, atom_key} -> Map.put(acc, atom_key, v)
        :error -> acc
      end
    end)
  end

  defp safe_to_atom(key) when is_atom(key), do: {:ok, key}

  defp safe_to_atom(key) when is_binary(key) do
    try do
      atom = String.to_existing_atom(key)
      if atom in @known_form_keys, do: {:ok, atom}, else: :error
    rescue
      ArgumentError -> :error
    end
  end

  defp safe_to_atom(_), do: :error

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
    missing_labels =
      for {field, label} <- required_fields,
          value = Map.get(form_data, field),
          is_nil(value) or value == "",
          do: label

    case missing_labels do
      [] -> :ok
      labels -> {:error, "Bitte füllen Sie alle Pflichtfelder aus: #{Enum.join(labels, ", ")}"}
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
