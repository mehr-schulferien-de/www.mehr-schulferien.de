defmodule MehrSchulferien.CalendarPdf.LatexTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.CalendarPdfFixtures

  alias MehrSchulferien.CalendarPdf
  alias MehrSchulferien.CalendarPdf.Latex
  alias MehrSchulferien.PdfGenerator

  setup do
    fixture = calendar_fixture()
    {:ok, state} = CalendarPdf.build({:federal_state, fixture}, 2027)
    {:ok, school} = CalendarPdf.build({:school, fixture}, 2027)

    {:ok, state: state, school: school}
  end

  describe "tex/1" do
    test "escapes what LaTeX would read as markup" do
      assert Latex.tex("A & B_1 #2 50% {x} $y$") == "A \\& B\\_1 \\#2 50\\% \\{x\\} \\$y\\$"
      assert Latex.tex("\\input{/etc/passwd}") == "\\textbackslash{}input\\{/etc/passwd\\}"
      assert Latex.tex("a~b^c") == "a\\textasciitilde{}b\\textasciicircum{}c"
    end

    test "keeps German letters and reduces what the font cannot set" do
      assert Latex.tex("Käthe-Kollwitz-Schule Gießen") == "Käthe-Kollwitz-Schule Gießen"
      assert Latex.tex("„Am Park“ – Škoda 🎒") == "''Am Park'' -- Skoda"
      assert Latex.tex(" zwei\n Zeilen ") == "zwei Zeilen"
      assert Latex.tex(nil) == ""
    end
  end

  describe "render/2" do
    test "the planner sets the paper size and names state, vacations and holidays",
         %{state: state} do
      a3 = Latex.render(state, "a3")
      a4 = Latex.render(state, "a4")
      a5 = Latex.render(state, "a5")

      assert a3 =~ "paperwidth=420mm,paperheight=297mm"
      assert a4 =~ "paperwidth=297mm,paperheight=210mm"
      assert a5 =~ "paperwidth=210mm,paperheight=148mm"

      assert a4 =~ "Schulferien Hessen 2027"
      assert a4 =~ "\\mbox{Sommerferien 28.06.--06.08.}"
      assert a4 =~ "\\mbox{Tag der Deutschen Einheit 03.10.}"

      assert a4 =~
               ~r/\{ferien\}\{28\}\{Mo\}\\Name\{[\d.]+\}\{[\d.]+\}\{Sommerferien\}\\Woche\{[\d.]+\}\{[\d.]+\}\{26\}\n/

      assert a4 =~ ~r/\{feiertag\}\{3\}\{So\}\\Name\{[\d.]+\}\{[\d.]+\}\{Tag der Deutschen\.\}\n/

      # 365 days in 2027
      assert length(Regex.scan(~r/^  \\Tag\{/m, a4)) == 365
    end

    test "the A5 planner leaves the names out of the day cells", %{state: state} do
      a5 = Latex.render(state, "a5")

      assert a5 =~ "{ferien}{28}{Mo}\n"
      refute a5 =~ "{Sommerferien}"
    end

    test "a school calendar carries name, address, page URL and bewegliche Ferientage",
         %{school: school} do
      for format <- CalendarPdf.formats() do
        latex = Latex.render(school, format)

        assert latex =~ "Goethe-Gymnasium \\& Co\\_1"
        assert latex =~ "Ysenburgstraße 41, 34117 Kassel"
        assert latex =~ "www.goethe-gymnasium-kassel.de"

        assert latex =~
                 "\\qrcode[height=13mm]{https://www.mehr-schulferien.de/ferien/d/schule/34117-goethe-gymnasium}"
      end

      assert Latex.render(school, "a4") =~
               ~r/\{beweglich\}\{7\}\{Fr\}\\Name\{[\d.]+\}\{[\d.]+\}\{bewegl\. Ferientag\}\n/

      assert Latex.render(school, "a4") =~ "\\textbf{Bewegliche Ferientage:} 07.05."
      assert Latex.render(school, "karte") =~ "Bewegl. Ferientag & 07.05."
    end

    test "a homepage too long for its line is cut back to the host", %{school: school} do
      long = %{school | homepage: "http://www.schule.example/" <> String.duplicate("seite/", 20)}

      for format <- ["a4", "karte"] do
        latex = Latex.render(long, format)

        assert latex =~ "www.schule.example"
        refute latex =~ "www.schule.example/seite"
      end
    end

    test "the card lists vacations on the front and holidays on the back", %{state: state} do
      latex = Latex.render(state, "karte")

      assert latex =~ "Sommerferien & 28.06.--06.08."
      assert latex =~ "Feiertage 2027"
      assert latex =~ "03.10. & Tag der Deutschen Einheit"
    end
  end

  describe "with pdflatex" do
    @describetag :pdflatex

    test "every format compiles to a one-page PDF", %{state: state, school: school} do
      # A name with every kind of character tex/1 lets through or rewrites.
      hostile = %{
        school
        | subtitle: "Schule „Am Park“ & Söhne_2 #1 100% {a} $b$ ~^<>|\\ Škoda àéîõü ÀÉÎÕÜ ß",
          address_lines: ["Straße des 17. Juni 1–3", "10623 Berlin"]
      }

      for calendar <- [state, school, hostile], format <- CalendarPdf.formats() do
        assert pdflatex_log(Latex.render(calendar, format)) =~ ".pdf (1 page,"
      end
    end

    test "the generator returns the PDF", %{state: state} do
      assert {:ok, "%PDF" <> _} =
               PdfGenerator.compile(Latex.render(state, "a4"), "ferienkalender_test")
    end
  end

  # Runs pdflatex itself to read its log: the page count is the proof that
  # the drawing fits the sheet.
  defp pdflatex_log(latex) do
    dir =
      Path.join(System.tmp_dir!(), "ferienkalender_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "kalender.tex"), latex)

    {log, status} =
      System.cmd(
        "pdflatex",
        [
          "-interaction=nonstopmode",
          "-halt-on-error",
          "-output-directory=#{dir}",
          "kalender.tex"
        ],
        cd: dir,
        stderr_to_stdout: true
      )

    File.rm_rf!(dir)
    assert status == 0, log
    log
  end
end
