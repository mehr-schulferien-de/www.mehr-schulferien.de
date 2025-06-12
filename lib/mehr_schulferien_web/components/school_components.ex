defmodule MehrSchulferienWeb.SchoolComponents do
  use Phoenix.Component
  import Phoenix.HTML.Link

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  def no_data(assigns) do
    ~H"""
    <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 mt-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="h-5 w-5 text-yellow-400"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-yellow-700">
            Keine Feriendaten für <%= @school.name %> im Jahr <%= @year %> verfügbar.
            <%= if length(@years_with_data) > 0 do %>
              Bitte wählen Sie ein verfügbares Jahr:
              <ul class="mt-2 list-disc pl-5 space-y-1">
                <%= for available_year <- @years_with_data do %>
                  <li>
                    <%= link("#{available_year}",
                      to:
                        Routes.school_path(
                          @conn,
                          :show_year,
                          @country.slug,
                          @school.slug,
                          available_year
                        ),
                      class: "font-medium text-blue-600 hover:text-blue-500"
                    ) %>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </p>
        </div>
      </div>
    </div>
    """
  end

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
            "name" => @school.name,
            "address" => %{
              "@type" => "PostalAddress",
              "streetAddress" => if(@school.address, do: @school.address.street, else: ""),
              "addressLocality" => @city.name,
              "postalCode" => if(@school.address, do: @school.address.zip_code, else: ""),
              "addressRegion" => @federal_state.name,
              "addressCountry" => @country.code
            }
          }
        }) %>
      </script>
    <% end %>
    """
  end

  def schema_org_school(assigns) do
    school = assigns.school
    city = assigns.city
    federal_state = assigns.federal_state
    country = assigns.country
    optional_fields = []

    optional_fields =
      if school.address do
        optional_fields ++
          [
            {"address",
             %{
               "@type" => "PostalAddress",
               "streetAddress" => school.address.street,
               "addressLocality" => city.name,
               "postalCode" => school.address.zip_code,
               "addressRegion" => federal_state.name,
               "addressCountry" => country.code
             }}
          ]
      else
        optional_fields
      end

    optional_fields =
      if school.address && school.address.phone_number do
        optional_fields ++ [{"telephone", school.address.phone_number}]
      else
        optional_fields
      end

    optional_fields =
      if school.address && school.address.email_address do
        optional_fields ++ [{"email", school.address.email_address}]
      else
        optional_fields
      end

    optional_fields =
      if school.address && school.address.homepage_url do
        optional_fields ++ [{"url", school.address.homepage_url}]
      else
        optional_fields
      end

    optional_fields = Map.new(optional_fields)
    assigns = assign(assigns, :optional_fields, optional_fields)

    ~H"""
    <script type="application/ld+json">
      <%= Jason.encode!(
        Map.merge(%{
          "@context" => "http://schema.org",
          "@type" => "School",
          "name" => @school.name,
          "geo" => %{
            "@type" => "GeoCoordinates",
            "latitude" => Map.get(@school, :latitude, ""),
            "longitude" => Map.get(@school, :longitude, "")
          }
        }, @optional_fields)
      ) %>
    </script>
    """
  end
end
