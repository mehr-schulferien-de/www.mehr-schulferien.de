defmodule MehrSchulferien.CalendarPdfTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.CalendarPdfFixtures

  alias MehrSchulferien.CalendarPdf
  alias MehrSchulferien.CalendarPdf.{Generator, Store}

  @today ~D[2027-03-01]

  setup do
    reset_calendar_pdfs()
    on_exit(&reset_calendar_pdfs/0)
    Application.put_env(:mehr_schulferien, :calendar_pdf_stub_listener, self())

    fixture = calendar_fixture()
    {:ok, Map.put(fixture, :state_scope, {:federal_state, fixture})}
  end

  defp pdf_files do
    Path.wildcard(Path.join(Store.dir(), "**/*.pdf"))
  end

  describe "build/2" do
    test "collects vacations and public holidays of a federal state", %{state_scope: scope} do
      assert {:ok, calendar} = CalendarPdf.build(scope, 2027)

      assert calendar.title == "Schulferien Hessen 2027"
      assert Enum.map(calendar.vacations, & &1.name) == ["Sommerferien", "Herbstferien"]
      assert Enum.map(calendar.holidays, & &1.name) == ["Tag der Deutschen Einheit"]
      assert calendar.address_lines == []
      assert calendar.days[~D[2027-07-01]].kind == :vacation
      assert calendar.days[~D[2027-10-03]].kind == :holiday
      assert calendar.days[~D[2027-03-06]].kind == :weekend
      assert calendar.days[~D[2027-03-08]].kind == :school
    end

    test "adds bewegliche Ferientage, address and page URL for a school", fixture do
      assert {:ok, calendar} = CalendarPdf.build({:school, fixture}, 2027)

      assert calendar.title == "Schulferien 2027"
      assert calendar.subtitle == "Goethe-Gymnasium & Co_1"
      assert calendar.address_lines == ["Ysenburgstraße 41", "34117 Kassel"]

      assert calendar.url ==
               "https://www.mehr-schulferien.de/ferien/d/schule/34117-goethe-gymnasium"

      assert calendar.days[~D[2027-05-07]].kind == :flexible
      assert [%{starts_on: ~D[2027-05-07]}] = calendar.flexible_days
    end

    test "has no calendar for a year without vacation data", %{state_scope: scope} do
      assert {:error, :no_data} = CalendarPdf.build(scope, 2031)
    end
  end

  describe "years/2" do
    test "offers the years from today on that have vacation data", %{state_scope: scope} do
      assert CalendarPdf.years(scope, @today) == [2027]
      assert CalendarPdf.years(scope, ~D[2028-01-01]) == []
    end

    test "the current year and the two after it are on offer" do
      assert CalendarPdf.offered_years([2029, 2026, 2027, 2027, 2030], @today) == [2027, 2029]
      refute CalendarPdf.offered_year?(2026, @today)
      assert CalendarPdf.offered_year?(2029, @today)
      refute CalendarPdf.offered_year?(2030, @today)
    end

    test "from October on next year's calendar is the suggested one" do
      assert CalendarPdf.suggested_year([2027, 2028], ~D[2027-09-30]) == 2027
      assert CalendarPdf.suggested_year([2027, 2028], ~D[2027-10-01]) == 2028
      assert CalendarPdf.suggested_year([2027], ~D[2027-10-01]) == 2027
      assert CalendarPdf.suggested_year([], ~D[2027-10-01]) == nil
    end
  end

  describe "fetch/3" do
    test "compiles a PDF once and serves the file afterwards", %{state_scope: scope} do
      assert {:ok, path} = CalendarPdf.fetch(scope, 2027, "a4")
      assert_received {:calendar_pdf_compiled, _latex}
      assert File.read!(path) =~ "%PDF"

      assert {:ok, ^path} = CalendarPdf.fetch(scope, 2027, "a4")
      refute_received {:calendar_pdf_compiled, _latex}
    end

    test "every format is its own file", %{state_scope: scope} do
      paths =
        for format <- CalendarPdf.formats() do
          assert {:ok, path} = CalendarPdf.fetch(scope, 2027, format)
          path
        end

      assert length(Enum.uniq(paths)) == 4
    end

    test "changed dates replace the stored file", %{state_scope: scope} = fixture do
      {:ok, old_path} = CalendarPdf.fetch(scope, 2027, "a4")

      vacation(fixture.federal_state, fixture.vacation_type, ~D[2027-12-23], ~D[2027-12-31])

      assert {:ok, new_path} = CalendarPdf.fetch(scope, 2027, "a4")
      assert new_path != old_path
      assert pdf_files() == [new_path]
    end

    test "rejects unknown formats and years without data", %{state_scope: scope} do
      assert {:error, :unknown_format} = CalendarPdf.fetch(scope, 2027, "a2")
      assert {:error, :no_data} = CalendarPdf.fetch(scope, 2031, "a4")
      assert pdf_files() == []
    end

    test "a failed compile leaves no file behind", %{state_scope: scope} do
      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_result, :error)

      assert {:error, _reason} = CalendarPdf.fetch(scope, 2027, "a4")
      assert Path.wildcard(Path.join(Store.dir(), "**/*")) |> Enum.filter(&File.regular?/1) == []
    end

    test "turns requests away while the generator queue is full", %{state_scope: scope} do
      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_delay, 300)
      Application.put_env(:mehr_schulferien, :calendar_pdf_max_queue, 1)

      # Staggered, so the first is being compiled and the second waits in the
      # queue before the others look at its length.
      tasks =
        for {format, index} <- Enum.with_index(CalendarPdf.formats()) do
          Task.async(fn ->
            Process.sleep(index * 50)
            CalendarPdf.fetch(scope, 2027, format)
          end)
        end

      assert [{:ok, _}, {:ok, _}, {:error, :busy}, {:error, :busy}] =
               Task.await_many(tasks, 5_000)
    end
  end

  describe "warm/1" do
    test "generates every format for every state and year with data" do
      assert CalendarPdf.warm(@today) == 4
      assert length(pdf_files()) == 4
      assert CalendarPdf.warm(@today) == 0
    end

    test "clears out past years and stale temporary files", %{state_scope: scope} do
      {:ok, path} = CalendarPdf.fetch(scope, 2027, "a4")
      folder = Path.dirname(path)
      old_temp = Path.join(folder, "2027-a4-0123456789abcdef.pdf.1.tmp")
      fresh_temp = Path.join(folder, "2027-a4-0123456789abcdef.pdf.2.tmp")
      File.write!(old_temp, "half")
      File.write!(fresh_temp, "half")
      File.touch!(old_temp, System.os_time(:second) - 7200)

      CalendarPdf.warm(@today)
      assert File.exists?(path)
      refute File.exists?(old_temp)
      assert File.exists?(fresh_temp)

      CalendarPdf.warm(~D[2028-01-01])
      refute File.exists?(path)
    end

    test "a run killed half-way is finished by the next one" do
      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_delay, 100)

      warmer = spawn(fn -> CalendarPdf.warm(@today) end)
      assert_receive {:calendar_pdf_compiled, _latex}, 2_000
      assert_receive {:calendar_pdf_compiled, _latex}, 2_000

      generator = Process.whereis(Generator)
      ref = Process.monitor(generator)
      Process.exit(warmer, :kill)
      Process.exit(generator, :kill)
      assert_receive {:DOWN, ^ref, :process, _pid, :killed}

      assert length(pdf_files()) < 4

      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_delay, 0)
      wait_for_generator()

      assert CalendarPdf.warm(@today) > 0
      assert length(pdf_files()) == 4
      assert Enum.all?(pdf_files(), &(File.read!(&1) =~ "%PDF"))
    end
  end

  defp wait_for_generator(attempts \\ 50) do
    cond do
      Process.whereis(Generator) -> :ok
      attempts == 0 -> flunk("Generator was not restarted")
      true -> Process.sleep(20) && wait_for_generator(attempts - 1)
    end
  end
end
