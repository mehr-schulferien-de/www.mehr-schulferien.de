defmodule MehrSchulferien.CalendarPdf.Warmer do
  @moduledoc """
  Keeps the state calendars generated ahead of the first request.

  Runs shortly after boot and then every few hours. A run only writes what is
  missing, so a deploy or crash in the middle of one costs nothing: the next
  boot finishes it. The periodic run also covers changed dates and the new
  year that comes into range on 1 January.
  """

  use GenServer

  require Logger

  alias MehrSchulferien.CalendarPdf
  alias MehrSchulferien.Calendars.DateHelpers

  @first_run :timer.seconds(30)
  @interval :timer.hours(6)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.send_after(self(), :warm, @first_run)
    {:ok, nil}
  end

  @impl true
  def handle_info(:warm, state) do
    Process.send_after(self(), :warm, @interval)

    case CalendarPdf.warm(DateHelpers.today_berlin()) do
      0 -> :ok
      generated -> Logger.info("Generated #{generated} calendar PDFs")
    end

    {:noreply, state}
  end
end
