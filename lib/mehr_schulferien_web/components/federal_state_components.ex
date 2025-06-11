defmodule MehrSchulferienWeb.FederalStateComponents do
  use Phoenix.Component

  def schema_org_event(assigns) do
    ~H"""
    <%= for period <- @periods do %>
      <script type="application/ld+json">
        <%= Jason.encode!(%{
          "@context" => "http://schema.org",
          "@type" => "Event",
          "name" => period.holiday_or_vacation_type.colloquial,
          "startDate" => period.starts_on,
          "endDate" => period.ends_on,
          "eventAttendanceMode" => "https://schema.org/OfflineEventAttendanceMode",
          "eventStatus" => "https://schema.org/EventScheduled",
          "location" => %{
            "@type" => "Place",
            "name" => @federal_state.name,
            "address" => %{
              "@type" => "PostalAddress",
              "streetAddress" => "",
              "addressLocality" => "",
              "postalCode" => "",
              "addressRegion" => @federal_state.name,
              "addressCountry" => @country.code
            }
          }
        }) %>
      </script>
    <% end %>
    """
  end
end
