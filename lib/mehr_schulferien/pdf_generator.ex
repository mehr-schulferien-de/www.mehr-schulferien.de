defmodule MehrSchulferien.PdfGenerator do
  @moduledoc """
  Generates PDF documents from LaTeX templates.
  """

  require Logger

  @temp_dir System.tmp_dir!()

  @doc """
  Generates an excuse letter PDF from form data and school information.

  Returns {:ok, pdf_binary} on success or {:error, reason} on failure.
  """
  def generate_entschuldigung_pdf(form_data, school) do
    template_path =
      Path.join(:code.priv_dir(:mehr_schulferien), "templates/entschuldigung.tex.eex")

    case File.read(template_path) do
      {:ok, template_content} ->
        latex_content =
          EEx.eval_string(template_content,
            assigns: [form_data: form_data, school: school],
            engine: EEx.SmartEngine
          )

        compile_latex_to_pdf(latex_content, "entschuldigung")

      {:error, reason} ->
        Logger.error("Failed to read LaTeX template: #{inspect(reason)}")
        {:error, "Template not found"}
    end
  end

  @doc """
  Generates a leave of absence request PDF from form data and school information.

  Returns {:ok, pdf_binary} on success or {:error, reason} on failure.
  """
  def generate_beurlaubung_pdf(form_data, school) do
    template_path =
      Path.join(:code.priv_dir(:mehr_schulferien), "templates/beurlaubung.tex.eex")

    case File.read(template_path) do
      {:ok, template_content} ->
        latex_content =
          EEx.eval_string(template_content,
            assigns: [form_data: form_data, school: school],
            engine: EEx.SmartEngine
          )

        compile_latex_to_pdf(latex_content, "beurlaubung")

      {:error, reason} ->
        Logger.error("Failed to read LaTeX template: #{inspect(reason)}")
        {:error, "Template not found"}
    end
  end

  @doc """
  Generates a sports exemption PDF from form data and school information.

  Returns {:ok, pdf_binary} on success or {:error, reason} on failure.
  """
  def generate_sportbefreiung_pdf(form_data, school) do
    template_path =
      Path.join(:code.priv_dir(:mehr_schulferien), "templates/sportbefreiung.tex.eex")

    case File.read(template_path) do
      {:ok, template_content} ->
        latex_content =
          EEx.eval_string(template_content,
            assigns: [form_data: form_data, school: school],
            engine: EEx.SmartEngine
          )

        compile_latex_to_pdf(latex_content, "sportbefreiung")

      {:error, reason} ->
        Logger.error("Failed to read LaTeX template: #{inspect(reason)}")
        {:error, "Template not found"}
    end
  end

  defp compile_latex_to_pdf(latex_content, base_filename) do
    # Create a unique filename to avoid conflicts
    timestamp = System.system_time(:microsecond)
    temp_filename = "#{base_filename}_#{timestamp}"
    tex_file = Path.join(@temp_dir, "#{temp_filename}.tex")
    pdf_file = Path.join(@temp_dir, "#{temp_filename}.pdf")

    # Ensure temp directory exists
    ensure_temp_dir()

    # Write LaTeX content to temporary file
    case File.write(tex_file, latex_content) do
      :ok ->
        compile_and_read_pdf(tex_file, pdf_file, temp_filename)

      {:error, reason} ->
        Logger.error("Failed to write LaTeX file: #{inspect(reason)}")
        cleanup_temp_files(temp_filename)
        {:error, "Failed to create temporary file"}
    end
  end

  defp ensure_temp_dir do
    case File.mkdir_p(@temp_dir) do
      :ok ->
        :ok

      {:error, :eexist} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to create temp directory: #{inspect(reason)}")
        :error
    end
  end

  defp compile_and_read_pdf(tex_file, pdf_file, temp_filename) do
    pdflatex_path = Application.get_env(:mehr_schulferien, :pdflatex_path, "pdflatex")

    try do
      case System.cmd(
             pdflatex_path,
             [
               "-interaction=nonstopmode",
               "-output-directory=#{@temp_dir}",
               tex_file
             ],
             stderr_to_stdout: true
           ) do
        {_output, 0} ->
          # Read the generated PDF
          case File.read(pdf_file) do
            {:ok, pdf_binary} ->
              {:ok, pdf_binary}

            {:error, reason} ->
              Logger.error("Failed to read generated PDF: #{inspect(reason)}")
              {:error, "PDF generation failed"}
          end

        {output, exit_code} ->
          Logger.error("pdflatex failed with exit code #{exit_code}: #{output}")
          {:error, "LaTeX compilation failed"}
      end
    rescue
      error in [ErlangError] ->
        Logger.error("Failed to execute pdflatex command: #{inspect(error)}")
        {:error, "PDF generation command not found or failed to execute"}
    after
      # Always clean up temporary files
      cleanup_temp_files(temp_filename)
    end
  end

  defp cleanup_temp_files(base_filename) do
    extensions = [".tex", ".pdf", ".aux", ".log", ".out"]

    Enum.each(extensions, fn ext ->
      file_path = Path.join(@temp_dir, "#{base_filename}#{ext}")
      File.rm(file_path)
    end)
  end

  # Template helper functions
  def format_full_name(form_data) do
    title = if form_data.title && form_data.title != "", do: "#{form_data.title} ", else: ""

    "#{title}#{form_data.first_name} #{form_data.last_name}"
  end

  def format_school_address(school, form_data) do
    if school.address do
      base_address = [school.name]

      # Add teacher information if available
      teacher_line = format_teacher_attention_line(form_data)
      base_address = if teacher_line, do: base_address ++ [teacher_line], else: base_address

      # Add street and then empty line (with non-breaking space) before city
      address_parts =
        base_address ++
          [school.address.street, "~", "#{school.address.zip_code} #{school.address.city}"]

      Enum.join(address_parts, "\\\\")
    else
      school.name
    end
  end

  defp format_teacher_attention_line(form_data) do
    teacher_name = Map.get(form_data, :teacher_name, "")
    teacher_salutation = Map.get(form_data, :teacher_salutation, "")

    if teacher_name && teacher_name != "" do
      salutation =
        case teacher_salutation do
          "Herr" -> "Herrn"
          _ -> teacher_salutation
        end

      "z.Hd. #{salutation} #{teacher_name}"
    else
      nil
    end
  end

  def format_personal_greeting(form_data) do
    teacher_name = Map.get(form_data, :teacher_name, "")
    teacher_salutation = Map.get(form_data, :teacher_salutation, "")

    if teacher_name && teacher_name != "" do
      salutation =
        case teacher_salutation do
          "Herr" -> "Sehr geehrter Herr"
          "Frau" -> "Sehr geehrte Frau"
          _ -> "Sehr geehrte(r)"
        end

      "#{salutation} #{teacher_name},"
    else
      "Sehr geehrte Damen und Herren,"
    end
  end

  def format_absence_reason(reason) do
    case reason do
      "krankheit" -> "wegen Krankheit"
      "arzttermin" -> "wegen eines Arzttermins"
      "familiaere_angelegenheiten" -> "wegen familiärer Angelegenheiten"
      "beerdigung" -> "wegen einer Beerdigung"
      "religioser_feiertag" -> "wegen eines religiösen Feiertags"
      _ -> "aus wichtigen Gründen"
    end
  end

  def format_absence_timeframe(form_data) do
    start_date = format_german_date(form_data.start_date)
    end_date = format_german_date(form_data.end_date)

    if form_data.start_date == form_data.end_date do
      "am #{start_date}"
    else
      "vom #{start_date} bis #{end_date}"
    end
  end

  def format_student_details(form_data) do
    case form_data.child_type do
      "mein_sohn" ->
        "meines Sohnes #{form_data.name_of_student} aus der Klasse #{form_data.class_name}"

      "meine_tochter" ->
        "meiner Tochter #{form_data.name_of_student} aus der Klasse #{form_data.class_name}"

      _ ->
        "von #{form_data.name_of_student} aus der Klasse #{form_data.class_name}"
    end
  end

  def format_detailed_reason(form_data) do
    # Use the child's name instead of "Mein Kind/Sohn/Tochter"
    child_name = form_data.name_of_student || "das Kind"

    case form_data.reason do
      "krankheit" ->
        "#{child_name} war aufgrund einer Erkrankung nicht in der Lage, am Unterricht teilzunehmen."

      "arzttermin" ->
        "Der Arzttermin für #{child_name} konnte leider nicht außerhalb der Schulzeit vereinbart werden."

      "familiaere_angelegenheiten" ->
        "Aufgrund wichtiger familiärer Angelegenheiten war eine Teilnahme am Unterricht für #{child_name} nicht möglich."

      "beerdigung" ->
        "Aufgrund einer Beerdigung in der Familie war #{child_name} verhindert."

      "religioser_feiertag" ->
        "Aufgrund eines religiösen Feiertags war #{child_name} verhindert."

      _ ->
        ""
    end
  end

  def format_german_date(date) do
    case date do
      %Date{} = d ->
        day = String.pad_leading("#{d.day}", 2, "0")
        month = String.pad_leading("#{d.month}", 2, "0")
        "#{day}.#{month}.#{d.year}"

      _ ->
        "#{date}"
    end
  end

  def format_sports_exemption_timeframe(form_data) do
    if form_data.duration_type == "single_lesson" do
      "am #{format_german_date(form_data.single_date)}"
    else
      start_date = format_german_date(form_data.start_date)
      end_date = format_german_date(form_data.end_date)

      if form_data.start_date == form_data.end_date do
        "am #{start_date}"
      else
        "vom #{start_date} bis #{end_date}"
      end
    end
  end

  # Formats the sender address line for the PDF (street, zip/city) without double commas if street is empty
  def format_sender_address(form_data) do
    street = form_data.street

    zip_city =
      Enum.join(Enum.filter([form_data.zip_code, form_data.city], &(&1 && &1 != "")), " ")

    if street && street != "" do
      Enum.join([street, zip_city], ", ")
    else
      zip_city
    end
  end
end
