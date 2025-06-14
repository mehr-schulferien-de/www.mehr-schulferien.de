defmodule MehrSchulferienWeb.EntschuldigungPdfController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, PdfGenerator}

  def download(conn, %{"school_slug" => school_slug} = params) do
    try do
      school = Locations.get_school_by_slug!(school_slug)

      # Extract and validate form data from params
      form_data = extract_form_data(params)

      case PdfGenerator.generate_entschuldigung_pdf(form_data, school) do
        {:ok, pdf_binary} ->
          filename = generate_filename(form_data)

          conn
          |> put_resp_content_type("application/pdf")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
          |> send_resp(200, pdf_binary)

        {:error, reason} ->
          conn
          |> put_flash(:error, "PDF konnte nicht erstellt werden: #{reason}")
          |> redirect(to: "/briefe/#{school_slug}/entschuldigung")
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("404.html")
    end
  end

  defp extract_form_data(params) do
    teacher_name = params["teacher_name"] || ""
    teacher_salutation = params["teacher_salutation"] || "Herr"

    greeting =
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

    %{
      title: params["title"] || "",
      first_name: params["first_name"] || "",
      last_name: params["last_name"] || "",
      street: params["street"] || "",
      zip_code: params["zip_code"] || "",
      city: params["city"] || "",
      name_of_student: params["name_of_student"] || "",
      class_name: params["class_name"] || "",
      greeting: greeting,
      reason: params["reason"] || "krankheit",
      start_date: parse_date(params["start_date"]),
      end_date: parse_date(params["end_date"]),
      child_type: params["child_type"] || "sonstiges"
    }
  end

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> Date.utc_today()
    end
  end

  defp parse_date(_), do: Date.utc_today()

  defp generate_filename(form_data) do
    student_name =
      form_data.name_of_student
      |> String.replace(~r/[^a-zA-ZäöüÄÖÜß0-9\s-]/, "")
      |> String.replace(~r/\s+/, "_")

    date_str = Date.to_iso8601(form_data.start_date)

    "Entschuldigung_#{student_name}_#{date_str}.pdf"
  end
end
