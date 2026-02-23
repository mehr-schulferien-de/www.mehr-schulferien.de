defmodule MehrSchulferienWeb.Helpers.HandwrittenBridgeDayImage do
  @moduledoc """
  Generates SVG images that look like handwritten bridge day notes on paper.
  These images are designed for SEO purposes to appear in search results.
  """

  alias MehrSchulferienWeb.Formatters.DateFormatter

  @doc """
  Generates an SVG image showing normal bridge days for display on the webpage.
  """
  def generate_svg(bridge_day_map, federal_state_name, year, public_periods) do
    generate_svg_with_dimensions(
      "100%",
      "100%",
      bridge_day_map,
      federal_state_name,
      year,
      public_periods
    )
  end

  @doc """
  Generates an SVG image showing normal bridge days with specific dimensions for social media.
  """
  def generate_svg_for_social(
        bridge_day_map,
        federal_state_name,
        year,
        public_periods
      ) do
    generate_svg_with_dimensions(
      "1200",
      "630",
      bridge_day_map,
      federal_state_name,
      year,
      public_periods
    )
  end

  defp generate_svg_with_dimensions(
         width,
         height,
         bridge_day_map,
         federal_state_name,
         year,
         public_periods
       ) do
    # Calculate viewbox based on dimensions
    {viewbox_width, viewbox_height} =
      if width == "100%" or height == "100%" do
        {600, 400}
      else
        {String.to_integer(width), String.to_integer(height)}
      end

    scale_factor =
      if width == "100%" or height == "100%" do
        1.0
      else
        viewbox_width / 600.0
      end

    # Set random seed for consistent generation
    :rand.seed(:exsss, {123, 456, 789})

    # Get all normal bridge days (2-day proposals)
    normal_bridge_days = Map.get(bridge_day_map, 2, [])

    # Create SVG with professional business style
    """
    <svg viewBox="0 0 #{viewbox_width} #{viewbox_height}" width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="bgGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" style="stop-color:#f8fafc;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#f1f5f9;stop-opacity:1" />
        </linearGradient>
        <filter id="dropShadow" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="2" dy="4" stdDeviation="3" flood-color="#64748b" flood-opacity="0.2"/>
        </filter>
      </defs>
      
      <!-- Professional background -->
      <rect width="100%" height="100%" fill="url(#bgGradient)"/>
      
      <!-- Main content card -->
      #{generate_content_card(viewbox_width, viewbox_height, scale_factor)}
      
      <!-- Title -->
      #{generate_title(federal_state_name, year, viewbox_width, viewbox_height, scale_factor)}
      
      <!-- Bridge days list -->
      #{generate_bridge_days_list(normal_bridge_days, public_periods, viewbox_width, viewbox_height, scale_factor)}
      
    </svg>
    """
  end

  defp generate_content_card(viewbox_width, viewbox_height, _scale_factor) do
    margin = viewbox_width * 0.05
    card_width = viewbox_width - margin * 2
    card_height = viewbox_height - margin * 2

    """
    <rect x="#{margin}" y="#{margin}" 
          width="#{card_width}" height="#{card_height}" 
          fill="white" 
          rx="8" ry="8" 
          filter="url(#dropShadow)"
          stroke="#e2e8f0" 
          stroke-width="1"/>
    """
  end

  defp generate_title(federal_state_name, year, viewbox_width, viewbox_height, scale_factor) do
    title_size = if scale_factor > 1.5, do: 72, else: 54
    subtitle_size = if scale_factor > 1.5, do: 48, else: 36
    y_position = viewbox_height * 0.22

    """
    <g>
      <text x="#{viewbox_width / 2}" y="#{y_position}" 
            font-family="Georgia, Times New Roman, serif" 
            font-size="#{title_size}" 
            fill="#1e293b" 
            font-weight="bold"
            text-anchor="middle">
        Brückentage #{year}
      </text>
      <text x="#{viewbox_width / 2}" y="#{y_position + title_size * 1.1}" 
            font-family="Georgia, Times New Roman, serif" 
            font-size="#{subtitle_size}" 
            fill="#475569" 
            text-anchor="middle">
        #{federal_state_name}
      </text>
      <line x1="#{viewbox_width * 0.15}" y1="#{y_position + title_size * 1.5}" 
            x2="#{viewbox_width * 0.85}" y2="#{y_position + title_size * 1.5}" 
            stroke="#cbd5e1" stroke-width="3"/>
    </g>
    """
  end

  defp generate_bridge_days_list(
         bridge_days,
         public_periods,
         viewbox_width,
         viewbox_height,
         scale_factor
       ) do
    # Sort bridge days by date
    sorted_bridge_days = Enum.sort_by(bridge_days, & &1.starts_on)

    # Take up to 3 bridge days for the display
    display_bridge_days = Enum.take(sorted_bridge_days, 3)

    # Calculate layout parameters
    text_size = if scale_factor > 1.5, do: 42, else: 32
    line_height = if scale_factor > 1.5, do: 70, else: 55
    start_y = viewbox_height * 0.56
    left_margin = viewbox_width * 0.15

    # Generate each bridge day entry
    entries =
      display_bridge_days
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {bridge_day, index} ->
        y_position = start_y + index * line_height

        # Format the date
        date_str = DateFormatter.format_date_full(bridge_day.starts_on)

        # Calculate gain
        all_periods =
          MehrSchulferien.Periods.list_periods_with_bridge_day(public_periods, bridge_day)

        gain = MehrSchulferienWeb.BridgeDayView.get_number_max_days(all_periods)

        # Professional bullet point
        bullet_color = "#3b82f6"
        bullet_size = if scale_factor > 1.5, do: 8, else: 6
        date_x_offset = if scale_factor > 1.5, do: 240, else: 180

        """
        <g>
          <circle cx="#{left_margin - 20}" cy="#{y_position - text_size / 3}"
                  r="#{bullet_size}"
                  fill="#{bullet_color}"/>
          <text x="#{left_margin}" y="#{y_position}"
                font-family="Arial, Helvetica, sans-serif"
                font-size="#{text_size}"
                fill="#1e293b"
                font-weight="600">
            #{date_str}
          </text>
          <text x="#{left_margin + date_x_offset}" y="#{y_position}"
                font-family="Arial, Helvetica, sans-serif"
                font-size="#{text_size}"
                fill="#059669"
                font-weight="bold">
            #{gain} Tage frei
          </text>
        </g>
        """
      end)

    # Add summary if there are more bridge days
    remaining = length(sorted_bridge_days) - length(display_bridge_days)

    summary =
      if remaining > 0 do
        y_position = start_y + length(display_bridge_days) * line_height + 15

        """
        <text x="#{left_margin}" y="#{y_position}" 
              font-family="Arial, Helvetica, sans-serif" 
              font-size="#{text_size * 0.8}" 
              fill="#64748b"
              font-style="italic">
          + #{remaining} weitere Brückentage
        </text>
        """
      else
        ""
      end

    entries <> summary
  end
end
