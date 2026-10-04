defmodule MehrSchulferien.CalendarPdf.Generator do
  @moduledoc """
  Runs pdflatex for calendar PDFs, one at a time.

  A single process does all the compiling, so a crawler walking the school
  calendars costs one busy CPU core, not one per request. Requests wait in its
  mailbox. A web request is turned away with `{:error, :busy}` when too many
  are waiting already or its turn does not come in time; the warmer waits as
  long as it takes.
  """

  use GenServer

  alias MehrSchulferien.CalendarPdf.Store

  @max_queue 10
  @shed_timeout :timer.seconds(30)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc "The module that turns LaTeX into a PDF binary."
  def compiler do
    Application.get_env(:mehr_schulferien, :calendar_pdf_compiler, MehrSchulferien.PdfGenerator)
  end

  @doc """
  Compiles `latex` and stores the PDF at `path`. Returns `{:ok, path, status}`
  with status `:generated` or `:stored` (another request was faster).

  `:shed` refuses the job when the queue is full, `:wait` always queues it.
  """
  def generate(path, latex, :wait), do: call(path, latex, :infinity)

  def generate(path, latex, :shed) do
    if queue_length() >= max_queue() do
      {:error, :busy}
    else
      call(path, latex, @shed_timeout)
    end
  end

  defp call(path, latex, timeout) do
    GenServer.call(__MODULE__, {:generate, path, latex}, timeout)
  catch
    # Not running, restarting, or slower than the caller is willing to wait.
    :exit, _reason -> {:error, :busy}
  end

  defp max_queue, do: Application.get_env(:mehr_schulferien, :calendar_pdf_max_queue, @max_queue)

  defp queue_length do
    with pid when is_pid(pid) <- Process.whereis(__MODULE__),
         {:message_queue_len, length} <- Process.info(pid, :message_queue_len) do
      length
    else
      _ -> 0
    end
  end

  @impl true
  def init(:ok), do: {:ok, nil}

  @impl true
  def handle_call({:generate, path, latex}, _from, state) do
    {:reply, generate_unless_stored(path, latex), state}
  end

  defp generate_unless_stored(path, latex) do
    if File.exists?(path) do
      {:ok, path, :stored}
    else
      case compiler().compile(latex, "ferienkalender") do
        {:ok, pdf} ->
          Store.write(path, pdf)
          {:ok, path, :generated}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
