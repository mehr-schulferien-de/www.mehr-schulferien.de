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

  @doc """
  Generates an SVG image showing all vacation periods for a federal state in a year.
  Returns the SVG as a string that can be embedded in HTML.
  """
  def generate_all_vacations_svg(vacation_periods, federal_state_name, year) do
    generate_all_vacations_svg_with_dimensions(
      "100%",
      "100%",
      vacation_periods,
      federal_state_name,
      year
    )
  end

  @doc """
  Generates an SVG image showing all vacation periods with specific dimensions for social media.
  """
  def generate_all_vacations_svg_for_social(vacation_periods, federal_state_name, year) do
    generate_all_vacations_svg_with_dimensions(
      "1200",
      "630",
      vacation_periods,
      federal_state_name,
      year
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

  defp generate_all_vacations_svg_with_dimensions(
         width,
         height,
         vacation_periods,
         federal_state_name,
         year
       ) do
    # Sort vacation periods by start date - ensure proper Date comparison
    # Take only the first 6 if there are more
    sorted_periods =
      vacation_periods
      |> Enum.sort_by(& &1.starts_on, {:asc, Date})
      |> Enum.take(6)

    # Determine if we're rendering for social media
    is_social = width != "100%" && height != "100%"

    # Set up dimensions and scaling
    {viewbox_width, viewbox_height, scale_factor} =
      if is_social do
        # Fixed size for social media with 3x scale
        {1200, 630, 3.0}
      else
        # Fixed dimensions for web display
        # Taller viewbox to fit more items
        {800, 400, 2.0}
      end

    # Determine column layout based on number of periods
    num_columns =
      cond do
        is_social and length(sorted_periods) <= 3 -> 1
        # Use 2 columns for 2x3 grid on social
        is_social and length(sorted_periods) <= 6 -> 2
        is_social -> 3
        length(sorted_periods) <= 2 -> 1
        # Use 2 columns for 3-6 items on web
        length(sorted_periods) <= 6 -> 2
        true -> 3
      end

    # Generate vacation entries based on column layout
    vacation_entries =
      case num_columns do
        1 ->
          # Single column layout
          sorted_periods
          |> Enum.with_index()
          |> Enum.map(fn {period, index} ->
            generate_compact_vacation_entry(period, index, 0, 1, scale_factor, viewbox_width)
          end)
          |> Enum.join("\n      ")

        2 ->
          # Two column layout
          sorted_periods
          |> Enum.with_index()
          |> Enum.map(fn {period, index} ->
            column = rem(index, 2)
            row = div(index, 2)
            generate_compact_vacation_entry(period, row, column, 2, scale_factor, viewbox_width)
          end)
          |> Enum.join("\n      ")

        3 ->
          # Three column layout
          sorted_periods
          |> Enum.with_index()
          |> Enum.map(fn {period, index} ->
            column = rem(index, 3)
            row = div(index, 3)
            generate_compact_vacation_entry(period, row, column, 3, scale_factor, viewbox_width)
          end)
          |> Enum.join("\n      ")
      end

    # Scale all sizes based on scale_factor
    paper_padding = 5 * scale_factor
    stroke_width = 1 * scale_factor
    hole_radius = 8 * scale_factor
    hole_x = 25 * scale_factor

    title_size =
      if scale_factor > 2.5 do
        # Fixed size for social media (about 18pt)
        55
      else
        # Smaller for web (20pt at 2x scale)
        40
      end

    state_size =
      if scale_factor > 2.5 do
        # Fixed size for social media (about 15pt)
        45
      else
        # Smaller for web (16pt at 2x scale)
        32
      end

    # No decoration for social media to save space
    # Use the existing doodles function for smaller version
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 #{viewbox_width} #{viewbox_height}" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet">
      <!-- Paper background with subtle texture -->
      <defs>
        <filter id="paperTexture">
          <feTurbulence type="fractalNoise" baseFrequency="0.02" numOctaves="5" result="noise" seed="1"/>
          <feDiffuseLighting in="noise" lighting-color="white" surfaceScale="1">
            <feDistantLight azimuth="45" elevation="60"/>
          </feDiffuseLighting>
        </filter>
      </defs>
      
      <!-- Paper background -->
      <rect width="#{viewbox_width}" height="#{viewbox_height}" fill="#FEFDF8" filter="url(#paperTexture)"/>
      
      <!-- Paper shadow -->
      <rect x="#{paper_padding}" y="#{paper_padding}" 
            width="#{viewbox_width - paper_padding * 2}" 
            height="#{viewbox_height - paper_padding * 2}" 
            fill="#00000010" rx="#{scale_factor * 2}"/>
      
      <!-- Main paper -->
      <rect x="#{paper_padding / 2}" y="#{paper_padding / 2}" 
            width="#{viewbox_width - paper_padding}" 
            height="#{viewbox_height - paper_padding}" 
            fill="#FFFEF9" stroke="#E8E8E8" stroke-width="#{stroke_width}" rx="#{scale_factor * 2}"/>
      
      <!-- Three-hole punch marks -->
      <circle cx="#{hole_x}" cy="#{viewbox_height * 0.2}" r="#{hole_radius}" fill="#F0F0F0" stroke="#DDD" stroke-width="#{stroke_width}"/>
      <circle cx="#{hole_x}" cy="#{viewbox_height * 0.5}" r="#{hole_radius}" fill="#F0F0F0" stroke="#DDD" stroke-width="#{stroke_width}"/>
      <circle cx="#{hole_x}" cy="#{viewbox_height * 0.8}" r="#{hole_radius}" fill="#F0F0F0" stroke="#DDD" stroke-width="#{stroke_width}"/>
      
      <!-- Title with handwritten style -->
      <text x="#{viewbox_width / 2}" y="#{if scale_factor > 2.5, do: 65, else: 70}" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="#{title_size}" fill="#1a365d">
        Schulferien #{year}
      </text>
      
      <!-- Underline with hand-drawn wobble -->
      <path d="M #{viewbox_width * 0.2} #{if scale_factor > 2.5, do: 90, else: 88} Q #{viewbox_width * 0.35} #{if scale_factor > 2.5, do: 87, else: 86} #{viewbox_width / 2} #{if scale_factor > 2.5, do: 90, else: 88} T #{viewbox_width * 0.8} #{if scale_factor > 2.5, do: 90, else: 88}" 
            stroke="#2563eb" stroke-width="#{2 * scale_factor}" fill="none" opacity="0.7"/>
      
      <!-- Federal state name -->
      <text x="#{viewbox_width / 2}" y="#{if scale_factor > 2.5, do: 160, else: 125}" text-anchor="middle" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="#{state_size}" fill="#374151">
        #{federal_state_name}
      </text>
      
      <!-- Vacation entries -->
      #{vacation_entries}
      
      <!-- Small hearts doodle -->
      #{if is_social do
      ""
    else
      generate_doodles()
    end}
      
    </svg>
    """
  end

  defp generate_compact_vacation_entry(
         period,
         row,
         column,
         num_columns,
         scale_factor,
         viewbox_width
       ) do
    # Format dates without year for compactness
    start_date = format_date_no_year(period.starts_on)
    end_date = format_date_no_year(period.ends_on)

    # Ultra-compact font sizes
    name_size =
      cond do
        scale_factor > 2.5 and num_columns == 3 ->
          # Smaller for 3 columns on social media
          42

        scale_factor > 2.5 ->
          # Fixed size for better readability (16pt)
          48

        true ->
          # One point larger (14pt at 2x scale)
          28
      end

    date_size =
      cond do
        scale_factor > 2.5 and num_columns == 3 ->
          # Smaller for 3 columns on social media
          36

        scale_factor > 2.5 ->
          # Fixed size for better readability (13pt)
          40

        true ->
          # One point larger (12pt at 2x scale)
          24
      end

    # Calculate positions based on grid layout - ultra compact
    y_spacing =
      if scale_factor > 2.5 do
        # More generous spacing between rows
        130
      else
        # Slightly tighter to fit with increased header space
        65
      end

    y_start =
      if scale_factor > 2.5 do
        # Move down 2-3 pixels more
        245
      else
        # More space after header
        180
      end

    # Calculate column width and x position - bring columns closer together
    effective_width =
      if num_columns == 2 and scale_factor > 2.5 do
        # Use only 70% of width for 2 columns
        viewbox_width * 0.7
      else
        viewbox_width
      end

    column_width = effective_width / num_columns

    # Calculate starting offset to center the columns - shift more to the left
    start_offset =
      if num_columns == 2 and scale_factor > 2.5 do
        # Reduced from 15% to move content left
        viewbox_width * 0.12
      else
        0
      end

    _x_padding =
      if scale_factor > 2.5 do
        20 * scale_factor
      else
        case num_columns do
          1 -> 60
          2 -> 50
          # More padding to spread out columns
          3 -> 40
        end
      end

    # Center each column in its allocated space
    column_center = start_offset + column * column_width + column_width / 2

    x_base =
      cond do
        num_columns == 2 ->
          # More offset for 2 columns to center better
          column_center - 80

        num_columns == 3 and scale_factor > 2.5 ->
          # Increased offset to prevent cutoff
          column_center - 120

        true ->
          # Standard offset
          column_center - 50
      end

    y_base = y_start + row * y_spacing

    # No rotation for cleaner look
    rotation = [0, 0]

    # Use full vacation name
    vacation_name = period.holiday_or_vacation_type.colloquial

    # Even more compact line spacing
    line_spacing =
      if scale_factor > 2.5 do
        # More generous spacing between name and date
        55
      else
        # A bit more space between name and date
        28
      end

    """
    <!-- #{period.holiday_or_vacation_type.colloquial} -->
    <g>
      <text x="#{x_base}" y="#{y_base}" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="#{name_size}" fill="#1e40af" font-weight="bold"
            transform="rotate(#{Enum.at(rotation, 0)} #{x_base} #{y_base})">
        #{vacation_name}
      </text>
      
      <text x="#{x_base + 5}" y="#{y_base + line_spacing}" 
            font-family="Comic Neue, Comic Sans MS, cursive" font-size="#{date_size}" fill="#dc2626"
            transform="rotate(#{Enum.at(rotation, 1)} #{x_base + 5} #{y_base + line_spacing})">
        #{start_date} - #{end_date}
      </text>
    </g>
    """
  end

  defp format_date_no_year(date) do
    day = date.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{day}.#{month}."
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
