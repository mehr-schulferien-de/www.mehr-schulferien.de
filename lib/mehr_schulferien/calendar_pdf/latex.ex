defmodule MehrSchulferien.CalendarPdf.Latex do
  @moduledoc """
  Turns a `MehrSchulferien.CalendarPdf` calendar into a LaTeX document.

  The year planner (A3, A4, A5) is designed once on an A4 landscape sheet in
  millimetres and scaled to the paper. This module computes the positions, the
  templates in `priv/templates` hold the drawing.

  School names and addresses are wiki content, so every string passes through
  `tex/1` before it reaches a template.
  """

  require EEx

  alias MehrSchulferien.Calendars.DateHelpers

  @templates Path.expand("../../../priv/templates", __DIR__)
  @planner_template Path.join(@templates, "ferienkalender.tex.eex")
  @card_template Path.join(@templates, "ferienkarte.tex.eex")
  @external_resource @planner_template
  @external_resource @card_template

  EEx.function_from_file(:defp, :planner, @planner_template, [:assigns])
  EEx.function_from_file(:defp, :card, @card_template, [:assigns])

  # The A4 design sheet of the year planner (297 x 210), in mm.
  @sheet_width 297
  @margin 8
  @grid_top 187
  @column_width (@sheet_width - 2 * @margin) / 12

  # Fonts in pt on the design sheet. A5 shrinks the sheet to 70 %, so it
  # starts from larger type and leaves out the names inside the day cells.
  @fonts %{day: "6.5", weekday: "5", footer: "6.5"}
  @large_fonts %{day: "7.5", weekday: "6", footer: "7.5"}
  @planner_layouts %{
    "a3" => %{paper: {420, 297}, scale: 1.4141, row_height: 5.1, labels: true, fonts: @fonts},
    "a4" => %{paper: {297, 210}, scale: 1.0, row_height: 5.1, labels: true, fonts: @fonts},
    "a5" => %{
      paper: {210, 148},
      scale: 0.7048,
      row_height: 4.6,
      labels: false,
      fonts: @large_fonts
    }
  }

  @label_length 19

  # Colour of a day by its kind: the name it has in the templates and its hex
  # value. The preview image draws from the same table.
  @palette %{
    holiday: {"feiertag", "F4B6AE"},
    flexible: {"beweglich", "FFE08A"},
    vacation: {"ferien", "BFE3C0"},
    weekend: {"wochenende", "E4E4E4"},
    school: {"schultag", "FFFFFF"}
  }

  @card_rows 14
  @card_holidays 16

  # Letters the default font encoding of the templates can typeset. Anything
  # else is reduced to its base letter or dropped: one character pdflatex
  # cannot set would fail the whole document.
  @letters String.graphemes("äöüÄÖÜßàáâèéêëìíîïòóôùúûçñÀÁÂÈÉÊËÌÍÎÏÒÓÔÙÚÛÇÑ")
  @escapes %{
    "\\" => "\\textbackslash{}",
    "{" => "\\{",
    "}" => "\\}",
    "$" => "\\$",
    "&" => "\\&",
    "#" => "\\#",
    "_" => "\\_",
    "%" => "\\%",
    "~" => "\\textasciitilde{}",
    "^" => "\\textasciicircum{}",
    "<" => "\\textless{}",
    ">" => "\\textgreater{}",
    "|" => "\\textbar{}",
    "\"" => "''",
    "`" => "'"
  }
  @replacements %{
    "„" => "''",
    "“" => "''",
    "”" => "''",
    "«" => "''",
    "»" => "''",
    "‚" => "'",
    "‘" => "'",
    "’" => "'",
    "´" => "'",
    "–" => "--",
    "—" => "--"
  }

  @doc "Renders the calendar in the given format (`a3`, `a4`, `a5` or `karte`)."
  def render(calendar, "karte"), do: card(card_assigns(calendar))
  def render(calendar, format), do: planner(planner_assigns(calendar, format))

  @doc "Hex colour (without `#`) of a day of the given kind."
  def color(kind), do: @palette |> Map.fetch!(kind) |> elem(1)

  @doc """
  Top left corner of a day's cell on the A4 design sheet in mm, measured from
  the bottom left of the sheet like everything in the planner template, and
  the size of a cell.
  """
  def cell(%Date{month: month, day: day}, row_height \\ @planner_layouts["a4"].row_height) do
    %{
      x: @margin + (month - 1) * @column_width,
      y: @grid_top - (day - 1) * row_height,
      width: @column_width,
      height: row_height
    }
  end

  @doc "Makes arbitrary text safe to place in a LaTeX document."
  def tex(nil), do: ""

  def tex(text) do
    text
    |> String.graphemes()
    |> Enum.map_join(&tex_grapheme/1)
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp tex_grapheme(grapheme) when is_map_key(@escapes, grapheme), do: @escapes[grapheme]

  defp tex_grapheme(grapheme) when is_map_key(@replacements, grapheme),
    do: @replacements[grapheme]

  defp tex_grapheme(grapheme) when grapheme in @letters, do: grapheme
  defp tex_grapheme(<<char>>) when char in 0x20..0x7E, do: <<char>>
  defp tex_grapheme(grapheme) when grapheme in ["\n", "\r", "\r\n", "\t", " "], do: " "

  defp tex_grapheme(grapheme) do
    grapheme
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-Za-z]/, "")
  end

  defp planner_assigns(calendar, format) do
    layout = Map.fetch!(@planner_layouts, format)
    {paper_width, paper_height} = layout.paper
    grid_bottom = @grid_top - 31 * layout.row_height

    %{
      paper_width: paper_width,
      paper_height: paper_height,
      scale: layout.scale,
      column_width: mm(@column_width),
      row_height: mm(layout.row_height),
      row_middle: mm(layout.row_height / 2),
      fonts: layout.fonts,
      title: tex(calendar.title),
      subtitle: calendar.subtitle |> short(90) |> tex(),
      address: calendar.address_lines |> Enum.join(", ") |> short(110) |> tex(),
      homepage: homepage_text(calendar.homepage, 90),
      url: calendar.url,
      url_text: url_text(calendar.url),
      colors: Map.values(@palette),
      months: for(month <- 1..12, do: {mm(cell(Date.new!(2000, month, 1)).x), month_name(month)}),
      cells: cells(calendar, layout),
      legend: legend(calendar),
      legend_y: mm(grid_bottom - 3.5),
      footer_y: mm(grid_bottom - 9.5),
      footer: footer(calendar)
    }
  end

  defp cells(calendar, layout) do
    for {date, day} <- Enum.sort_by(calendar.days, fn {date, _day} -> Date.to_erl(date) end) do
      monday? = Date.day_of_week(date) == 1

      %{
        x: mm(cell(date, layout.row_height).x),
        y: mm(cell(date, layout.row_height).y),
        fill: @palette |> Map.fetch!(day.kind) |> elem(0),
        day: date.day,
        weekday: DateHelpers.weekday(Date.day_of_week(date), :short),
        label: if(layout.labels, do: label(day.kind, day.label, monday?)),
        week: if(monday? and layout.labels, do: week_number(date))
      }
    end
  end

  defp label(_kind, nil, _monday?), do: nil
  defp label(:flexible, _label, _monday?), do: "bewegl. Ferientag"

  # Mondays share the cell with the week number.
  defp label(_kind, label, monday?) do
    label |> short(if(monday?, do: @label_length - 3, else: @label_length)) |> tex()
  end

  defp week_number(date) do
    {_year, week} = :calendar.iso_week_number(Date.to_erl(date))
    week
  end

  defp legend(calendar) do
    [{"ferien", "Schulferien"}, {"feiertag", "Feiertag"}, {"wochenende", "Wochenende"}] ++
      if calendar.flexible_days == [], do: [], else: [{"beweglich", "Beweglicher Ferientag"}]
  end

  defp footer(calendar) do
    named = &"\\mbox{#{tex(&1.name)} #{date_range(&1, calendar.year)}}"
    dated = &date_range(&1, calendar.year)

    [
      {"Ferien", calendar.vacations, named},
      {"Bewegliche Ferientage", calendar.flexible_days, dated},
      {"Feiertage", calendar.holidays, named}
    ]
    |> Enum.reject(fn {_heading, entries, _format} -> entries == [] end)
    |> Enum.map(fn {heading, entries, format} ->
      {heading, Enum.map_join(entries, "\\quad ", format)}
    end)
  end

  defp card_assigns(calendar) do
    flexible_days = Enum.map(calendar.flexible_days, &%{&1 | name: "Bewegl. Ferientag"})

    rows =
      (calendar.vacations ++ flexible_days)
      |> Enum.sort_by(&Date.to_erl(&1.starts_on))
      |> Enum.take(@card_rows)
      |> Enum.map(&card_row(&1, calendar.year, 30))

    holidays =
      calendar.holidays
      |> Enum.take(@card_holidays)
      |> Enum.map(&card_row(&1, calendar.year, 28))

    %{
      title: tex(calendar.title),
      subtitle: calendar.subtitle |> short(52) |> tex(),
      address: calendar.address_lines |> Enum.join(", ") |> short(70) |> tex(),
      homepage: homepage_text(calendar.homepage, 70),
      url: calendar.url,
      url_text: calendar.url |> url_text() |> String.replace("/", "/\\allowbreak "),
      year: calendar.year,
      rows: rows,
      row_font: card_font(length(rows)),
      holiday_columns: Enum.chunk_every(holidays, max(ceil(length(holidays) / 2), 1))
    }
  end

  defp card_row(entry, year, name_length) do
    {entry.name |> short(name_length) |> tex(), date_range(entry, year)}
  end

  # Font size and line height in pt that fit the given number of rows.
  defp card_font(rows) when rows <= 6, do: {"7.5", "9.6"}
  defp card_font(rows) when rows <= 8, do: {"6.5", "8.4"}
  defp card_font(rows) when rows <= 11, do: {"5.5", "7"}
  defp card_font(_rows), do: {"4.8", "6"}

  # "28.06.--06.08.", a single day as "03.10.". A period that leaves the year
  # of the calendar says which years it means.
  defp date_range(%{starts_on: day, ends_on: day}, _year), do: short_date(day)

  defp date_range(%{starts_on: %{year: year} = starts_on, ends_on: %{year: year} = ends_on}, year) do
    "#{short_date(starts_on)}--#{short_date(ends_on)}"
  end

  defp date_range(%{starts_on: starts_on, ends_on: ends_on}, _year) do
    "#{dated(starts_on)}--#{dated(ends_on)}"
  end

  defp short_date(date), do: Calendar.strftime(date, "%d.%m.")
  defp dated(date), do: Calendar.strftime(date, "%d.%m.%y")

  defp url_text(url), do: url |> display_url() |> tex()

  # A web address as one would type it: no scheme, no trailing slash.
  defp display_url(url) do
    url |> String.trim() |> String.replace(~r{^https?://}i, "") |> String.trim_trailing("/")
  end

  # The school's own website. One that does not fit is cut back to its host:
  # a truncated path would print an address that leads nowhere.
  defp homepage_text(nil, _length), do: ""

  defp homepage_text(url, length) do
    shown = display_url(url)

    if String.length(shown) > length do
      shown |> String.split("/") |> hd() |> tex()
    else
      tex(shown)
    end
  end

  defp month_name(month), do: DateHelpers.get_months_map()[month]

  defp short(nil, _length), do: nil

  defp short(text, length) do
    if String.length(text) > length do
      String.trim_trailing(String.slice(text, 0, length - 1)) <> "."
    else
      text
    end
  end

  defp mm(number), do: :erlang.float_to_binary(number / 1, decimals: 2)
end
