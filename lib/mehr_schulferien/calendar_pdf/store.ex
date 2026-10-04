defmodule MehrSchulferien.CalendarPdf.Store do
  @moduledoc """
  The directory the generated calendar PDFs live in.

  One file per scope, year and format, named `<year>-<format>-<hash>.pdf`
  after a hash of its LaTeX source. A file is written under a temporary name
  and renamed, so a path that exists is always a complete PDF.
  """

  @hash_length 16
  @temp_suffix ".tmp"
  @stale_temp_seconds 3600

  @doc "Root directory of the store."
  def dir do
    Application.get_env(:mehr_schulferien, :calendar_pdf_dir) ||
      Path.join([:code.priv_dir(:mehr_schulferien), "static", "cache", "calendar_pdfs"])
  end

  @doc "Where the PDF built from `latex` is or will be stored."
  def path(scope_key, year, format, latex) do
    hash =
      :crypto.hash(:sha256, latex)
      |> Base.encode16(case: :lower)
      |> binary_part(0, @hash_length)

    folder = String.replace(scope_key, ~r/[^a-z0-9-]/, "_")

    Path.join([dir(), folder, "#{year}-#{format}-#{hash}.pdf"])
  end

  @doc """
  Stores `pdf` at `path` and removes the files of the same calendar that were
  built from older data.
  """
  def write(path, pdf) do
    File.mkdir_p!(Path.dirname(path))

    temp = "#{path}.#{System.unique_integer([:positive])}#{@temp_suffix}"
    File.write!(temp, pdf)
    File.rename!(temp, path)

    path
    |> String.replace(~r/[0-9a-f]{#{@hash_length}}\.pdf$/, "*.pdf")
    |> Path.wildcard()
    |> Enum.reject(&(&1 == path))
    |> Enum.each(&File.rm/1)

    :ok
  end

  @doc """
  Removes what nobody will ask for again: calendars of the years before
  `current_year`, and temporary files a killed generator left behind. The
  generator may be writing while this runs, so a temporary file has to be an
  hour old.
  """
  def sweep(current_year) do
    now = System.os_time(:second)

    for file <- Path.wildcard(Path.join(dir(), "*/*")), stale?(file, current_year, now) do
      File.rm(file)
    end

    :ok
  end

  defp stale?(file, current_year, now) do
    if String.ends_with?(file, @temp_suffix) do
      case File.stat(file, time: :posix) do
        {:ok, %{mtime: mtime}} -> now - mtime > @stale_temp_seconds
        _ -> false
      end
    else
      case Integer.parse(Path.basename(file)) do
        {year, "-" <> _rest} -> year < current_year
        _ -> false
      end
    end
  end
end
