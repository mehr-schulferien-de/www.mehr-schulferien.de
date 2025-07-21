defmodule MehrSchulferien.PdfGeneratorTest do
  use ExUnit.Case, async: false

  alias MehrSchulferien.PdfGenerator

  describe "format helpers" do
    test "format_full_name/1 formats name with title" do
      form_data = %{
        title: "Dr.",
        first_name: "Max",
        last_name: "Mustermann"
      }

      assert PdfGenerator.format_full_name(form_data) == "Dr. Max Mustermann"
    end

    test "format_full_name/1 formats name without title" do
      form_data = %{
        title: "",
        first_name: "Max",
        last_name: "Mustermann"
      }

      assert PdfGenerator.format_full_name(form_data) == "Max Mustermann"
    end

    test "format_full_name/1 handles nil title" do
      form_data = %{
        title: nil,
        first_name: "Max",
        last_name: "Mustermann"
      }

      assert PdfGenerator.format_full_name(form_data) == "Max Mustermann"
    end

    test "format_german_date/1 formats Date struct" do
      date = ~D[2024-01-15]
      assert PdfGenerator.format_german_date(date) == "15.01.2024"
    end

    test "format_german_date/1 pads single digit days and months" do
      date = ~D[2024-05-09]
      assert PdfGenerator.format_german_date(date) == "09.05.2024"
    end

    test "format_german_date/1 handles non-Date input" do
      assert PdfGenerator.format_german_date("2024-01-15") == "2024-01-15"
    end

    test "format_absence_reason/1 returns correct German phrases" do
      assert PdfGenerator.format_absence_reason("krankheit") == "wegen Krankheit"
      assert PdfGenerator.format_absence_reason("arzttermin") == "wegen eines Arzttermins"

      assert PdfGenerator.format_absence_reason("familiaere_angelegenheiten") ==
               "wegen familiärer Angelegenheiten"

      assert PdfGenerator.format_absence_reason("beerdigung") == "wegen einer Beerdigung"

      assert PdfGenerator.format_absence_reason("religioser_feiertag") ==
               "wegen eines religiösen Feiertags"

      assert PdfGenerator.format_absence_reason("unknown") == "aus wichtigen Gründen"
    end

    test "format_absence_timeframe/1 formats single day" do
      form_data = %{
        start_date: ~D[2024-01-15],
        end_date: ~D[2024-01-15]
      }

      assert PdfGenerator.format_absence_timeframe(form_data) == "am 15.01.2024"
    end

    test "format_absence_timeframe/1 formats date range" do
      form_data = %{
        start_date: ~D[2024-01-15],
        end_date: ~D[2024-01-17]
      }

      assert PdfGenerator.format_absence_timeframe(form_data) == "vom 15.01.2024 bis 17.01.2024"
    end

    test "format_student_details/1 formats for son" do
      form_data = %{
        child_type: "mein_sohn",
        name_of_student: "Max Mustermann",
        class_name: "5a"
      }

      assert PdfGenerator.format_student_details(form_data) ==
               "meines Sohnes Max Mustermann aus der Klasse 5a"
    end

    test "format_student_details/1 formats for daughter" do
      form_data = %{
        child_type: "meine_tochter",
        name_of_student: "Anna Mustermann",
        class_name: "5b"
      }

      assert PdfGenerator.format_student_details(form_data) ==
               "meiner Tochter Anna Mustermann aus der Klasse 5b"
    end

    test "format_student_details/1 formats for generic case" do
      form_data = %{
        child_type: "other",
        name_of_student: "Alex Mustermann",
        class_name: "5c"
      }

      assert PdfGenerator.format_student_details(form_data) ==
               "von Alex Mustermann aus der Klasse 5c"
    end

    test "format_detailed_reason/1 formats illness reason" do
      form_data = %{
        reason: "krankheit",
        name_of_student: "Max"
      }

      assert PdfGenerator.format_detailed_reason(form_data) ==
               "Max war aufgrund einer Erkrankung nicht in der Lage, am Unterricht teilzunehmen."
    end

    test "format_detailed_reason/1 handles missing student name" do
      form_data = %{
        reason: "krankheit",
        name_of_student: nil
      }

      assert PdfGenerator.format_detailed_reason(form_data) ==
               "das Kind war aufgrund einer Erkrankung nicht in der Lage, am Unterricht teilzunehmen."
    end

    test "format_personal_greeting/1 with male teacher" do
      form_data = %{
        teacher_name: "Schmidt",
        teacher_salutation: "Herr"
      }

      assert PdfGenerator.format_personal_greeting(form_data) == "Sehr geehrter Herr Schmidt,"
    end

    test "format_personal_greeting/1 with female teacher" do
      form_data = %{
        teacher_name: "Müller",
        teacher_salutation: "Frau"
      }

      assert PdfGenerator.format_personal_greeting(form_data) == "Sehr geehrte Frau Müller,"
    end

    test "format_personal_greeting/1 without teacher info" do
      form_data = %{
        teacher_name: "",
        teacher_salutation: ""
      }

      assert PdfGenerator.format_personal_greeting(form_data) == "Sehr geehrte Damen und Herren,"
    end

    test "format_sports_exemption_timeframe/1 for single lesson" do
      form_data = %{
        duration_type: "single_lesson",
        single_date: ~D[2024-01-15]
      }

      assert PdfGenerator.format_sports_exemption_timeframe(form_data) == "am 15.01.2024"
    end

    test "format_sports_exemption_timeframe/1 for date range" do
      form_data = %{
        duration_type: "date_range",
        start_date: ~D[2024-01-15],
        end_date: ~D[2024-01-20]
      }

      assert PdfGenerator.format_sports_exemption_timeframe(form_data) ==
               "vom 15.01.2024 bis 20.01.2024"
    end

    test "format_sender_address/1 with all fields" do
      form_data = %{
        street: "Musterstraße 123",
        zip_code: "12345",
        city: "Berlin"
      }

      assert PdfGenerator.format_sender_address(form_data) == "Musterstraße 123, 12345 Berlin"
    end

    test "format_sender_address/1 without street" do
      form_data = %{
        street: "",
        zip_code: "12345",
        city: "Berlin"
      }

      assert PdfGenerator.format_sender_address(form_data) == "12345 Berlin"
    end

    test "format_sender_address/1 with nil street" do
      form_data = %{
        street: nil,
        zip_code: "12345",
        city: "Berlin"
      }

      assert PdfGenerator.format_sender_address(form_data) == "12345 Berlin"
    end

    test "format_sender_address/1 with only city" do
      form_data = %{
        street: "",
        zip_code: "",
        city: "Berlin"
      }

      assert PdfGenerator.format_sender_address(form_data) == "Berlin"
    end
  end

  describe "format_school_address/2" do
    test "formats school address with all details" do
      school = %{
        name: "Test Grundschule",
        address: %{
          street: "Schulstraße 1",
          zip_code: "12345",
          city: "Berlin"
        }
      }

      form_data = %{}

      expected = "Test Grundschule\\\\Schulstraße 1\\\\~\\\\12345 Berlin"
      assert PdfGenerator.format_school_address(school, form_data) == expected
    end

    test "formats school address with teacher attention line" do
      school = %{
        name: "Test Grundschule",
        address: %{
          street: "Schulstraße 1",
          zip_code: "12345",
          city: "Berlin"
        }
      }

      form_data = %{
        teacher_name: "Schmidt",
        teacher_salutation: "Herr"
      }

      expected = "Test Grundschule\\\\z.Hd. Herrn Schmidt\\\\Schulstraße 1\\\\~\\\\12345 Berlin"
      assert PdfGenerator.format_school_address(school, form_data) == expected
    end

    test "formats school without address" do
      school = %{
        name: "Test Grundschule",
        address: nil
      }

      form_data = %{}

      assert PdfGenerator.format_school_address(school, form_data) == "Test Grundschule"
    end
  end

  describe "PDF generation functions" do
    @moduledoc """
    These tests verify the function signatures and basic error handling.
    Actual PDF generation requires pdflatex to be installed, which may not
    be available in all test environments.
    """

    test "module exports expected functions" do
      # Ensure module is loaded
      Code.ensure_loaded(PdfGenerator)
      
      # Check all PDF generation functions
      assert function_exported?(PdfGenerator, :generate_entschuldigung_pdf, 2)
      assert function_exported?(PdfGenerator, :generate_beurlaubung_pdf, 2)
      assert function_exported?(PdfGenerator, :generate_sportbefreiung_pdf, 2)
    end

  end

  describe "edge cases" do
    test "format_detailed_reason/1 with unknown reason returns empty string" do
      form_data = %{
        reason: "unknown_reason",
        name_of_student: "Test"
      }

      assert PdfGenerator.format_detailed_reason(form_data) == ""
    end

    test "format functions handle empty/minimal maps gracefully" do
      # format_full_name needs at least the name keys
      minimal_name_data = %{
        title: nil,
        first_name: "",
        last_name: ""
      }
      assert PdfGenerator.format_full_name(minimal_name_data) == " "
      
      # format_personal_greeting can handle empty map
      assert PdfGenerator.format_personal_greeting(%{}) == "Sehr geehrte Damen und Herren,"
    end
  end
end