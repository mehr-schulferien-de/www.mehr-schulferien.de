defmodule MehrSchulferienWeb.VacationView do
  use MehrSchulferienWeb, :view

  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.ICalPanelComponent
  import MehrSchulferienWeb.FederalStateComponents
  import MehrSchulferienWeb.FederalState.FaqSchemaComponent
  import MehrSchulferienWeb.FederalState.LastUpdatedComponent

  @doc """
  Returns planning tips for each vacation type
  """
  def vacation_planning_tip("sommerferien") do
    "Die Sommerferien sind die längsten Ferien des Jahres. Beliebte Reiseziele sind früh ausgebucht - planen Sie rechtzeitig!"
  end

  def vacation_planning_tip("osterferien") do
    "Osterferien eignen sich ideal für Städtereisen oder erste Wanderungen. Beachten Sie die variablen Osterfeiertage!"
  end

  def vacation_planning_tip("herbstferien") do
    "Herbstferien bieten sich für Wanderurlaub oder Städtereisen an. Die Nebensaison bietet oft günstigere Preise."
  end

  def vacation_planning_tip("weihnachtsferien") do
    "Weihnachtsferien umfassen Weihnachten und Silvester. Familienbesuche und Winterurlaub früh planen!"
  end

  def vacation_planning_tip("winterferien") do
    "Winterferien sind ideal für Skiurlaub. In manchen Bundesländern gibt es keine Winterferien."
  end

  def vacation_planning_tip("pfingstferien") do
    "Pfingstferien dauern meist nur wenige Tage. Perfekt für Kurzurlaube oder verlängerte Wochenenden."
  end

  def vacation_planning_tip(_) do
    "Nutzen Sie die Ferienzeit für gemeinsame Aktivitäten mit der Familie."
  end

  @doc """
  Returns the relevant months to display for a vacation period
  """
  def get_relevant_months(%{starts_on: starts_on, ends_on: ends_on}) do
    start_month = starts_on.month
    end_month = ends_on.month

    # Handle year transition
    if start_month > end_month do
      # Vacation spans year boundary (e.g., Christmas vacation)
      Enum.to_list(start_month..12) ++ Enum.to_list(1..end_month)
    else
      # Normal case
      months = Enum.to_list(start_month..end_month)

      # Add one month before and after if reasonable
      months_with_context =
        if start_month > 1, do: [start_month - 1 | months], else: months

      months_with_context =
        if end_month < 12 and length(months_with_context) < 3,
          do: months_with_context ++ [end_month + 1],
          else: months_with_context

      # Limit to max 3 months for better layout
      Enum.take(months_with_context, 3)
    end
  end

  def get_relevant_months(_), do: []

  @doc """
  Generates dynamic meta description based on vacation proximity
  """
  def dynamic_vacation_description(vacation_name, year, state_name, vacation_period, today) do
    if vacation_period do
      date_range =
        "#{Calendar.strftime(vacation_period.starts_on, "%d.%m.")}-#{Calendar.strftime(vacation_period.ends_on, "%d.%m.%Y")}"

      duration = Date.diff(vacation_period.ends_on, vacation_period.starts_on) + 1

      cond do
        # Vacation is ongoing
        Date.compare(today, vacation_period.starts_on) != :lt &&
            Date.compare(today, vacation_period.ends_on) != :gt ->
          days_left = Date.diff(vacation_period.ends_on, today)

          "🎉 #{vacation_name} #{year} in #{state_name} laufen noch #{days_left} Tage! Bis #{Calendar.strftime(vacation_period.ends_on, "%d.%m.%Y")}. Alle Ferientermine mit Kalender & iCal-Export."

        # Vacation is upcoming within 30 days
        Date.diff(vacation_period.starts_on, today) in 1..30 ->
          days_until = Date.diff(vacation_period.starts_on, today)

          "⏰ Nur noch #{days_until} Tage bis zu den #{vacation_name}! #{state_name} #{year}: #{date_range} (#{duration} Tage). Jetzt Urlaub planen!"

        # Vacation is upcoming within 60 days
        Date.diff(vacation_period.starts_on, today) in 31..60 ->
          days_until = Date.diff(vacation_period.starts_on, today)

          "📅 #{vacation_name} #{year} in #{state_name} beginnen in #{days_until} Tagen: #{date_range}. Frühbucher sparen! Plus alle Ferientermine #{year}."

        # Vacation just ended (within 7 days)
        Date.diff(today, vacation_period.ends_on) in 1..7 ->
          "#{vacation_name} #{year} in #{state_name} sind vorbei. Nächste Ferien planen: Alle kommenden Ferientermine mit Kalender & iCal-Export."

        # Default description
        true ->
          "#{vacation_name} #{year} in #{state_name}: #{date_range} (#{duration} Tage). Kalenderansicht, iCal-Export, Reiseplanung und alle anderen Ferientermine #{year}."
      end
    else
      "#{vacation_name} #{year} Termine für #{state_name} - Alle Schulferien im Überblick mit Kalender, iCal-Export und Planungstipps."
    end
  end
end
