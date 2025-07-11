defmodule MehrSchulferienWeb.FederalState.ItemListSchemaComponent do
  use Phoenix.Component
  alias MehrSchulferienWeb.ViewHelpers

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :federal_state, :any, required: true
  attr :year, :integer, required: true

  def itemlist_schema(assigns) do
    # Create list items for each vacation period
    vacation_items =
      assigns.periods
      |> Enum.filter(fn p -> p.holiday_or_vacation_type.is_school_vacation end)
      |> Enum.with_index(1)
      |> Enum.map(fn {period, position} ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, assigns.all_periods)

        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => period.holiday_or_vacation_type.name,
          "item" => %{
            "@type" => "Event",
            "name" =>
              "#{period.holiday_or_vacation_type.name} #{assigns.federal_state.name} #{assigns.year}",
            "startDate" => period.starts_on,
            "endDate" => period.ends_on,
            "duration" => "P#{days}D",
            "description" =>
              "#{period.holiday_or_vacation_type.name} in #{assigns.federal_state.name}: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} bis #{Calendar.strftime(period.ends_on, "%d.%m.%Y")} (#{effective_duration} Tage inkl. Wochenenden)",
            "location" => %{
              "@type" => "Place",
              "name" => assigns.federal_state.name,
              "address" => %{
                "@type" => "PostalAddress",
                "addressRegion" => assigns.federal_state.name,
                "addressCountry" => "DE"
              }
            }
          }
        }
      end)

    assigns = assign(assigns, :vacation_items, vacation_items)

    ~H"""
    <script type="application/ld+json">
      <%= Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "ItemList",
        "name" => "Schulferien #{@federal_state.name} #{@year}",
        "description" => "Vollständige Liste aller Schulferien #{@year} in #{@federal_state.name} mit Terminen und Dauer",
        "numberOfItems" => length(@vacation_items),
        "itemListElement" => @vacation_items
      }) %>
    </script>
    """
  end
end
