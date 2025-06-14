defmodule MehrSchulferienWeb.EntschuldigungLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Locations

  @impl true
  def mount(%{"school_slug" => school_slug}, _session, socket) do
    # Get school information
    school = Locations.get_school_by_slug!(school_slug)

    # Get yesterday's date for prepopulation
    yesterday = Date.add(Date.utc_today(), -1)

    # Initialize form with default values
    form_data = %{
      gender: "",
      title: "",
      first_name: "",
      last_name: "",
      street: "",
      zip_code: "",
      city: "",
      name_of_student: "",
      class_name: "",
      reason: "",
      start_date: yesterday,
      end_date: yesterday
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

    # For now, just show a success message
    # TODO: Generate PDF here
    {:noreply,
     socket
     |> assign(form_data: form_data)
     |> put_flash(:info, "Entschuldigung-Daten erfasst. PDF-Erstellung folgt in Kürze.")}
  end

  # Helper functions
  defp atomize_keys(params) do
    Enum.into(params, %{}, fn {k, v} -> {String.to_atom(k), v} end)
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
