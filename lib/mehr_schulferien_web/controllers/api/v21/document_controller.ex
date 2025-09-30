defmodule MehrSchulferienWeb.Api.V21.DocumentController do
  @moduledoc """
  API v2.1 controller for document generation (PDF).

  Provides endpoints for:
  - Generating PDFs for schools (Entschuldigung, Beurlaubung, Sportbefreiung)
  """
  use MehrSchulferienWeb.Api.V21.BaseController

  alias MehrSchulferien.PdfGenerator

  @doc """
  POST /api/v2.1/schools/:slug/documents

  Generates a PDF document for a school.

  ## Request Body

  ### Common fields (all document types):
  - `type` (required): "entschuldigung", "beurlaubung", or "sportbefreiung"
  - `first_name` (required): First name of the sender
  - `last_name` (required): Last name of the sender
  - `zip_code` (required): ZIP code
  - `city` (required): City name
  - `name_of_student` (required): Student's full name
  - `class_name` (required): Class name (e.g., "5a")
  - `title` (optional): Title (e.g., "Dr.")
  - `street` (optional): Street and house number
  - `teacher_name` (optional): Teacher's name
  - `teacher_salutation` (optional): "Herr" or "Frau"
  - `child_type` (optional): "mein_sohn", "meine_tochter", or "sonstiges"

  ### Entschuldigung-specific fields:
  - `reason` (required): "krankheit", "arzttermin", "familiaere_angelegenheiten", "beerdigung", or "religioser_feiertag"
  - `start_date` (required): Start date (ISO 8601, e.g., "2025-01-15")
  - `end_date` (required): End date (ISO 8601)

  ### Beurlaubung-specific fields:
  - `start_date` (required): Start date (ISO 8601)
  - `end_date` (required): End date (ISO 8601)
  - `detailed_reason` (optional): Detailed explanation

  ### Sportbefreiung-specific fields:
  - `duration_type` (required): "single_lesson" or "multiple_days"
  - `single_date` (required if duration_type is "single_lesson"): Date (ISO 8601)
  - `start_date` (required if duration_type is "multiple_days"): Start date (ISO 8601)
  - `end_date` (required if duration_type is "multiple_days"): End date (ISO 8601)
  - `detailed_reason` (optional): Detailed medical reason
  - `medical_certificate` (optional): Boolean, default false

  ## Response

  - Success (200): PDF binary with Content-Type: application/pdf
  - Error (400): JSON error response with details
  - Error (404): School not found
  """
  def create(conn, %{"slug" => school_slug} = params) do
    with {:ok, school} <- get_school_by_slug(school_slug),
         {:ok, document_type} <- validate_document_type(params),
         {:ok, form_data} <- extract_and_validate_form_data(params, document_type) do
      school = Repo.preload(school, :address)

      pdf_result =
        case document_type do
          "entschuldigung" -> PdfGenerator.generate_entschuldigung_pdf(form_data, school)
          "beurlaubung" -> PdfGenerator.generate_beurlaubung_pdf(form_data, school)
          "sportbefreiung" -> PdfGenerator.generate_sportbefreiung_pdf(form_data, school)
        end

      case pdf_result do
        {:ok, pdf_binary} ->
          filename = generate_filename(form_data, document_type)

          conn
          |> put_resp_header("content-type", "application/pdf")
          |> put_resp_header("content-disposition", "attachment; filename=#{filename}")
          |> send_resp(200, pdf_binary)

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "PDF generation failed: #{reason}"})
      end
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "School not found"})

      {:error, :invalid_document_type} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error:
            "Invalid document type. Must be one of: entschuldigung, beurlaubung, sportbefreiung"
        })

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  # Private functions

  defp get_school_by_slug(slug) do
    query =
      from l in Location,
        where: l.slug == ^slug and l.is_school == true

    case Repo.one(query) do
      nil -> {:error, :not_found}
      school -> {:ok, school}
    end
  end

  defp validate_document_type(%{"type" => type})
       when type in ["entschuldigung", "beurlaubung", "sportbefreiung"] do
    {:ok, type}
  end

  defp validate_document_type(_), do: {:error, :invalid_document_type}

  defp extract_and_validate_form_data(params, document_type) do
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

    # Add document-specific fields
    data_with_type =
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
          |> Map.put(:medical_certificate, params["medical_certificate"] == true)
      end

    # Validate required fields
    case validate_required_fields(data_with_type, document_type) do
      :ok -> {:ok, data_with_type}
      {:error, message} -> {:error, message}
    end
  end

  defp validate_required_fields(form_data, _document_type) do
    # Common required fields
    required_fields = [
      {:first_name, "First name"},
      {:last_name, "Last name"},
      {:zip_code, "ZIP code"},
      {:city, "City"},
      {:name_of_student, "Student name"},
      {:class_name, "Class name"}
    ]

    missing_fields =
      Enum.filter(required_fields, fn {field, _label} ->
        value = Map.get(form_data, field)
        value == nil or value == ""
      end)

    case missing_fields do
      [] ->
        :ok

      fields ->
        field_names = Enum.map(fields, fn {_field, label} -> label end)
        {:error, "Missing required fields: #{Enum.join(field_names, ", ")}"}
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
