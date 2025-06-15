defmodule MehrSchulferienWeb.EntschuldigungLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Locations

  @impl true
  def mount(%{"school_slug" => school_slug}, _session, socket) do
    # Get school information
    school = Locations.get_school_by_slug!(school_slug)

    # Initialize form with default values
    form_data = %{
      title: "",
      first_name: "",
      last_name: "",
      street: "",
      zip_code: "",
      city: "",
      name_of_student: "",
      class_name: "",
      reason: "krankheit",
      start_date: Date.utc_today(),
      end_date: Date.utc_today(),
      teacher_salutation: "Herr",
      teacher_name: "",
      child_type: "mein_sohn"
    }

    {:ok,
     assign(socket,
       school: school,
       form_data: form_data,
       page_title: "Entschuldigung - #{school.name}"
     )}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form_data =
      socket.assigns.form_data
      |> Map.merge(atomize_keys(params))
      |> maybe_parse_dates()

    {:noreply, assign(socket, form_data: form_data)}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    form_data =
      socket.assigns.form_data
      |> Map.merge(atomize_keys(params))
      |> maybe_parse_dates()

    # Validate required fields
    case validate_form_data(form_data) do
      :ok ->
        # Generate PDF download URL with form data as query parameters
        pdf_url = build_pdf_url(socket.assigns.school.slug, form_data)

        # Keep form data instead of resetting it so user can reuse or modify
        {:noreply,
         socket
         |> assign(form_data: form_data)
         |> put_flash(
           :info,
           "PDF wurde erfolgreich erstellt. Sie können das Formular erneut ausfüllen oder die Daten anpassen."
         )
         |> push_event("open_pdf", %{url: pdf_url})}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(form_data: form_data)
         |> put_flash(:error, message)}
    end
  end

  # Helper functions
  defp atomize_keys(params) do
    params = Enum.into(params, %{}, fn {k, v} -> {String.to_atom(k), v} end)
    params
  end

  defp maybe_parse_dates(form_data) do
    form_data
    |> parse_date_field(:start_date)
    |> parse_date_field(:end_date)
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

  # Form validation
  defp validate_form_data(form_data) do
    required_fields = [
      {:first_name, "Vorname"},
      {:last_name, "Nachname"},
      {:zip_code, "PLZ"},
      {:city, "Stadt"},
      {:name_of_student, "Name des Schülers/der Schülerin"},
      {:class_name, "Klasse"}
    ]

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

  # Build PDF download URL with form data
  defp build_pdf_url(school_slug, form_data) do
    query_params =
      form_data
      |> Map.new(fn {key, value} ->
        {to_string(key), format_param_value(value)}
      end)
      |> URI.encode_query()

    "/briefe/#{school_slug}/entschuldigung/pdf?#{query_params}"
  end

  defp format_param_value(%Date{} = date), do: Date.to_iso8601(date)
  defp format_param_value(value) when is_binary(value), do: value
  defp format_param_value(value), do: to_string(value)

  # Get available reasons for the dropdown
  defp reasons do
    [
      {"Krankheit", "krankheit"},
      {"Arzttermin", "arzttermin"},
      {"Familiäre Angelegenheiten", "familiaere_angelegenheiten"},
      {"Beerdigung", "beerdigung"},
      {"Religiöser Feiertag", "religioser_feiertag"}
    ]
  end
end
