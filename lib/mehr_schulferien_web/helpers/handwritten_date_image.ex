defmodule MehrSchulferienWeb.Helpers.HandwrittenDateImage do
  @moduledoc """
  Generates SVG images that look like handwritten vacation dates on paper.
  These images are designed for SEO purposes to appear in search results.
  """

  alias MehrSchulferienWeb.Formatters.DateFormatter

  @doc """
  Generates an SVG image of handwritten vacation dates on a piece of paper.
  Returns the SVG as a string that can be embedded in HTML or saved as a file.
  """
  def generate_svg(vacation_period, vacation_name, federal_state_name, year, all_periods \\ []) do
    generate_svg_with_dimensions(
      "100%",
      "100%",
      vacation_period,
      vacation_name,
      federal_state_name,
      year,
      all_periods
    )
  end

  @doc """
  Generates an SVG image with specific dimensions for social media sharing.
  """
  def generate_svg_for_social(
        vacation_period,
        vacation_name,
        federal_state_name,
        year,
        all_periods \\ []
      ) do
    generate_svg_with_dimensions(
      "1200",
      "630",
      vacation_period,
      vacation_name,
      federal_state_name,
      year,
      all_periods
    )
  end

  defp generate_svg_with_dimensions(
         width,
         height,
         vacation_period,
         vacation_name,
         federal_state_name,
         year,
         all_periods
       ) do
    # Format dates
    start_date = DateFormatter.format_date_full(vacation_period.starts_on)
    end_date = DateFormatter.format_date_full(vacation_period.ends_on)

    # Calculate both official and effective duration
    official_duration = Date.diff(vacation_period.ends_on, vacation_period.starts_on) + 1

    effective_duration =
      if length(all_periods) > 0 do
        MehrSchulferienWeb.ViewHelpers.calculate_effective_duration(vacation_period, all_periods)
      else
        official_duration
      end

    # Calculate additional days if any
    additional_days = effective_duration - official_duration

    # Create SVG with handwritten style
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 400 320" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet">
      <!-- Paper background with subtle texture -->
      <defs>
        <filter id="paperTexture">
          <feTurbulence type="fractalNoise" baseFrequency="0.02" numOctaves="5" result="noise" seed="1"/>
          <feDiffuseLighting in="noise" lighting-color="white" surfaceScale="1">
            <feDistantLight azimuth="45" elevation="60"/>
          </feDiffuseLighting>
        </filter>
        <filter id="roughPaper">
          <feTurbulence type="turbulence" baseFrequency="0.02" numOctaves="5" result="turbulence"/>
          <feComposite operator="in" in2="turbulence"/>
        </filter>
      </defs>
      
      
      <!-- Paper background -->
      <rect width="400" height="320" fill="#FEFDF8" filter="url(#paperTexture)"/>
      
      <!-- Paper shadow -->
      <rect x="5" y="5" width="390" height="310" fill="#00000010" rx="2"/>
      
      <!-- Main paper -->
      <rect x="2" y="2" width="396" height="316" fill="#FFFEF9" stroke="#E8E8E8" stroke-width="1" rx="2"/>
      
      <!-- Subtle paper lines -->
      #{generate_paper_lines()}
      
      <!-- Three-hole punch marks -->
      <circle cx="25" cy="60" r="8" fill="#F0F0F0" stroke="#DDD" stroke-width="1"/>
      <circle cx="25" cy="160" r="8" fill="#F0F0F0" stroke="#DDD" stroke-width="1"/>
      <circle cx="25" cy="260" r="8" fill="#F0F0F0" stroke="#DDD" stroke-width="1"/>
      
      <!-- Title with handwritten style -->
      <text x="200" y="65" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="30" fill="#1a365d" 
            transform="rotate(-1 200 65)">
        #{vacation_name} #{year}
      </text>
      
      <!-- Underline with hand-drawn wobble -->
      <path d="M 80 78 Q 140 76 200 78 T 320 78" 
            stroke="#2563eb" stroke-width="2" fill="none" opacity="0.7"/>
      
      <!-- Federal state name -->
      <text x="200" y="110" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="22" fill="#374151" 
            transform="rotate(0.5 200 110)">
        #{federal_state_name}
      </text>
      
      <!-- Date range with larger, emphasized font -->
      <text x="200" y="155" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="28" fill="#dc2626" font-weight="bold"
            transform="rotate(-0.5 200 155)">
        #{start_date}
      </text>
      
      <!-- "bis" (to) -->
      <text x="200" y="185" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="20" fill="#4b5563"
            transform="rotate(0.3 200 185)">
        bis
      </text>
      
      <!-- End date -->
      <text x="200" y="215" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="28" fill="#dc2626" font-weight="bold"
            transform="rotate(0.7 200 215)">
        #{end_date}
      </text>
      
      <!-- Duration in days with circle -->
      <g transform="translate(170, 265)">
        <!-- Hand-drawn circle -->
        <path d="M -65 0 Q -65 -30 -30 -42 T 30 -42 Q 65 -30 65 0 T 30 42 Q 0 50 -30 42 T -65 0" 
              stroke="#059669" stroke-width="2.5" fill="none" opacity="0.8"/>
        <text text-anchor="middle" 
              font-family="Comic Neue, Comic Sans MS, cursive" font-size="26" fill="#059669" font-weight="bold"
              transform="rotate(-1)">
          #{official_duration} Tage
        </text>
      </g>
      
      #{if additional_days > 0 do
      """
      <!-- Additional days note - looks like someone added it later -->
      <g transform="translate(245, 265) rotate(-8)">
        <text font-family="Comic Neue, Comic Sans MS, cursive" font-size="22" fill="#dc2626" opacity="0.9" font-weight="bold">
          +#{additional_days}
        </text>
      </g>
      <g transform="translate(240, 278) rotate(-8)">
        <path d="M 0 0 Q 10 2 20 -1 T 35 0" stroke="#dc2626" stroke-width="2" fill="none" opacity="0.8"/>
      </g>
      """
    else
      ""
    end}
      
      <!-- Small doodles for authenticity -->
      #{generate_doodles()}
      
      #{if additional_days > 0 do
      """
      <!-- Scribbled note about weekends -->
      <g transform="translate(245, 293) rotate(3)">
        <text font-family="Comic Neue, Comic Sans MS, cursive" font-size="11" fill="#6B7280" opacity="0.7">
          mit WE
        </text>
      </g>
      """
    else
      ""
    end}
      
    </svg>
    """
  end

  defp generate_paper_lines do
    Enum.map(Enum.take_every(50..290, 30), fn y ->
      "<line x1=\"50\" y1=\"#{y}\" x2=\"350\" y2=\"#{y + :rand.uniform(3) - 2}\" stroke=\"#E5E7EB\" stroke-width=\"1\" opacity=\"0.5\"/>"
    end)
    |> Enum.join("\n      ")
  end

  defp generate_doodles do
    # Add some simple doodles for authenticity
    doodles = [
      # Small hearts
      "<path d=\"M 330 240 C 330 237, 327 234, 324 234 C 321 234, 318 237, 318 240 C 318 237, 315 234, 312 234 C 309 234, 306 237, 306 240 Q 306 248, 318 256 Q 330 248, 330 240 Z\" fill=\"#EF4444\" opacity=\"0.6\"/>"
    ]

    Enum.join(doodles, "\n      ")
  end

  @doc """
  Generates a data URI for embedding the SVG directly in HTML
  """
  def generate_data_uri(
        vacation_period,
        vacation_name,
        federal_state_name,
        year,
        all_periods \\ []
      ) do
    svg =
      generate_svg_for_social(
        vacation_period,
        vacation_name,
        federal_state_name,
        year,
        all_periods
      )

    encoded = Base.encode64(svg)
    "data:image/svg+xml;base64,#{encoded}"
  end

  @doc """
  Generates Open Graph meta tags for the handwritten image
  """
  def meta_tags(
        conn,
        vacation_period,
        vacation_name,
        federal_state_name,
        year,
        _all_periods \\ []
      ) do
    # Get the vacation type slug from the vacation_period
    vacation_slug = "#{vacation_period.holiday_or_vacation_type.slug}ferien"

    # Get the federal state slug from conn assigns
    federal_state = conn.assigns[:federal_state]
    federal_state_slug = if federal_state, do: federal_state.slug, else: ""

    # Build the full URL for the image using url helper without port
    # Use hardcoded production URL to avoid port issues
    image_url =
      "https://www.mehr-schulferien.de/#{vacation_slug}/#{federal_state_slug}/#{year}/handwritten.webp"

    [
      {"og:image", image_url},
      {"og:image:type", "image/webp"},
      {"og:image:width", "1200"},
      {"og:image:height", "630"},
      {"og:image:alt",
       "#{vacation_name} #{federal_state_name} #{year} - Handgeschriebene Ferientermine"},
      {"twitter:image", image_url},
      {"twitter:card", "summary_large_image"}
    ]
  end
end
