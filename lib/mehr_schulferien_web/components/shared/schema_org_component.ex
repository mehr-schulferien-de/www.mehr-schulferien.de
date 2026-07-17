defmodule MehrSchulferienWeb.Shared.SchemaOrgComponent do
  @moduledoc """
  Shared schema.org JSON-LD markup for holiday/vacation periods.

  Renders one `Event` script tag per period. The location-specific parts
  (city, federal state, school) are passed in as a prebuilt `place` map, so
  the page-specific component modules only have to describe their place.
  """
  use Phoenix.Component

  @doc """
  Renders schema.org Event JSON-LD script tags for the given periods.

  Periods without a `holiday_or_vacation_type` are skipped.

  ## Assigns

    * `:periods` - list of periods with `holiday_or_vacation_type` preloaded
    * `:place` - map describing the schema.org Place of the events with the
      keys `:name`, `:street`, `:locality`, `:zip`, `:region` and `:country`
  """
  def schema_org_event(assigns) do
    ~H"""
    <%= for period <- @periods, period.holiday_or_vacation_type do %>
      <script type="application/ld+json">
        <%= Phoenix.HTML.raw(Jason.encode!(%{
          "@context" => "http://schema.org",
          "@type" => "Event",
          "name" => period.holiday_or_vacation_type.colloquial,
          "startDate" => period.starts_on,
          "endDate" => period.ends_on,
          "eventAttendanceMode" => "https://schema.org/OfflineEventAttendanceMode",
          "eventStatus" => "https://schema.org/EventScheduled",
          "location" => %{
            "@type" => "Place",
            "name" => @place.name,
            "address" => %{
              "@type" => "PostalAddress",
              "streetAddress" => @place.street,
              "addressLocality" => @place.locality,
              "postalCode" => @place.zip,
              "addressRegion" => @place.region,
              "addressCountry" => @place.country
            }
          }
        })) %>
      </script>
    <% end %>
    """
  end
end
