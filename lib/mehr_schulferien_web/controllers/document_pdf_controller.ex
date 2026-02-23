defmodule MehrSchulferienWeb.DocumentPdfController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, PdfGenerator}

  def download(conn, %{"school_slug" => school_slug, "document_type" => document_type} = params) do
    school = Locations.get_school_by_slug!(school_slug)

    # Extract and validate form data from params
    form_data = extract_form_data(params, document_type)

    # Generate PDF based on document type
    pdf_result =
      case document_type do
        "entschuldigung" -> PdfGenerator.generate_entschuldigung_pdf(form_data, school)
        "beurlaubung" -> PdfGenerator.generate_beurlaubung_pdf(form_data, school)
        "sportbefreiung" -> PdfGenerator.generate_sportbefreiung_pdf(form_data, school)
        _ -> {:error, "Unknown document type"}
      end

    case pdf_result do
      {:ok, pdf_binary} ->
        filename = generate_filename(form_data, document_type)

        conn
        |> send_download({:binary, pdf_binary},
          filename: filename,
          content_type: "application/pdf"
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, "PDF konnte nicht erstellt werden: #{reason}")
        |> redirect(to: "/briefe/#{school_slug}/#{document_type}")
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(MehrSchulferienWeb.ErrorHTML)
      |> render("404.html")
  end

  defp extract_form_data(params, document_type) do
    # Common fields
    base_data = %{
      title: params["title"] || "",
      first_name: params["first_name"] || "",
      last_name: params["last_name"] || "",
      street: params["street"] || "",
      zip_code: params["zip_code"] || "",
      city: params["city"] || "",
      name_of_student: params["name_of_student"] || "",
      class_name: params["class_name"] || "",
      teacher_name: params["teacher_name"] || "",
      teacher_salutation: params["teacher_salutation"] || "Herr",
      child_type: params["child_type"] || "sonstiges"
    }

    # Add greeting
    base_data = Map.put(base_data, :greeting, generate_greeting(base_data))

    # Add document-specific fields
    case document_type do
      "entschuldigung" ->
        base_data
        |> Map.put(:reason, params["reason"] || "krankheit")
        |> Map.put(:start_date, parse_date(params["start_date"]))
        |> Map.put(:end_date, parse_date(params["end_date"]))

      "beurlaubung" ->
        base_data
        |> Map.put(:start_date, parse_date(params["start_date"]))
        |> Map.put(:end_date, parse_date(params["end_date"]))
        |> Map.put(:detailed_reason, params["detailed_reason"] || "")

      "sportbefreiung" ->
        base_data
        |> Map.put(:duration_type, params["duration_type"] || "single_lesson")
        |> Map.put(:single_date, parse_date(params["single_date"]))
        |> Map.put(:start_date, parse_date(params["start_date"]))
        |> Map.put(:end_date, parse_date(params["end_date"]))
        |> Map.put(:detailed_reason, params["detailed_reason"] || "")
        |> Map.put(:medical_certificate, params["medical_certificate"] == "true")

      _ ->
        base_data
    end
  end

  defp generate_greeting(%{teacher_name: teacher_name, teacher_salutation: teacher_salutation}) do
    if teacher_name != "" do
      salutation =
        case teacher_salutation do
          "Herr" -> "Sehr geehrter Herr"
          "Frau" -> "Sehr geehrte Frau"
          _ -> "Sehr geehrte(r)"
        end

      salutation <> " " <> teacher_name <> ","
    else
      "Sehr geehrte Damen und Herren,"
    end
  end

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> Date.utc_today()
    end
  end

  defp parse_date(_), do: Date.utc_today()

  defp generate_filename(form_data, document_type) do
    student_name =
      form_data.name_of_student
      |> String.replace(~r/[^a-zA-ZäöüÄÖÜß0-9\s-]/, "")
      |> String.replace(~r/\s+/, "_")

    date_str = generate_date_string(form_data, document_type)
    document_name = get_document_name(document_type)

    "#{document_name}_#{student_name}_#{date_str}.pdf"
  end

  defp generate_date_string(
         %{single_date: single_date, duration_type: "single_lesson"},
         "sportbefreiung"
       ) do
    Date.to_iso8601(single_date)
  end

  defp generate_date_string(%{start_date: start_date, end_date: end_date}, _) do
    if start_date == end_date do
      Date.to_iso8601(start_date)
    else
      "#{Date.to_iso8601(start_date)}_bis_#{Date.to_iso8601(end_date)}"
    end
  end

  defp get_document_name("entschuldigung"), do: "Entschuldigung"
  defp get_document_name("beurlaubung"), do: "Beurlaubung"
  defp get_document_name("sportbefreiung"), do: "Sportbefreiung"
  defp get_document_name(_), do: "Dokument"
end
