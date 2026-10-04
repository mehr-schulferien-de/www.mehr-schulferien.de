defmodule MehrSchulferien.CalendarPdfStubCompiler do
  @moduledoc """
  Stands in for pdflatex in the test suite, so calendar PDF tests run without
  a TeX installation. Reports every compile to the configured listener and can
  be slowed down to let a test interrupt a run.
  """

  def available?, do: true

  def compile(latex, _base_filename) do
    case Application.get_env(:mehr_schulferien, :calendar_pdf_stub_listener) do
      nil -> :ok
      pid -> send(pid, {:calendar_pdf_compiled, latex})
    end

    Process.sleep(Application.get_env(:mehr_schulferien, :calendar_pdf_stub_delay, 0))

    case Application.get_env(:mehr_schulferien, :calendar_pdf_stub_result, :ok) do
      :ok -> {:ok, "%PDF-1.5 stub\n" <> latex}
      :error -> {:error, "LaTeX compilation failed"}
    end
  end
end
