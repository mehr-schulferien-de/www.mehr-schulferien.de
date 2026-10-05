defmodule MehrSchulferien.CalendarPdf.Preview do
  @moduledoc """
  A small picture of the year planner, as SVG.

  Drawn from the same calendar as the PDF, with the cell positions and day
  colours `MehrSchulferien.CalendarPdf.Latex` gives the A4 sheet, so the
  thumbnail next to a download shows the dates the file will have. It is meant
  for a few hundred pixels: days are coloured cells without text, the footer
  and the QR code are sketched, and the grid lines are lighter than in print.
  """

  alias MehrSchulferien.CalendarPdf.Latex

  @sheet_height 210
  @ink "#2B2B2B"
  @sketch "#E4E4E4"

  @doc "Renders the calendar as an SVG document in A4 landscape proportions."
  def svg(calendar) do
    cells =
      for {date, day} <- calendar.days do
        cell = Latex.cell(date)

        [
          ~s(<rect x="),
          mm(cell.x),
          ~s(" y="),
          # SVG counts from the top of the sheet, the planner from the bottom.
          mm(@sheet_height - cell.y),
          ~s(" width="),
          mm(cell.width),
          ~s(" height="),
          mm(cell.height),
          ~s(" fill="#),
          Latex.color(day.kind),
          ~s("/>)
        ]
      end

    IO.iodata_to_binary([
      ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 297 #{@sheet_height}">),
      ~s(<rect width="297" height="#{@sheet_height}" fill="#FFFFFF"/>),
      ~s(<g font-family="Helvetica, Arial, sans-serif" fill="#{@ink}">),
      ~s(<text x="8" y="12" font-size="8" font-weight="700">),
      text(calendar.title),
      ~s(</text><text x="289" y="12" text-anchor="end" font-size="5">),
      text(calendar.subtitle),
      ~s(</text><rect x="8" y="17" width="281" height="6"/>),
      ~s(<rect x="276" y="189" width="13" height="13"/></g>),
      ~s(<g stroke="#C9C9C9" stroke-width=".25">),
      cells,
      ~s(</g><g fill="#{@sketch}"><rect x="8" y="187" width="150" height="2.4"/>),
      ~s(<rect x="8" y="192" width="205" height="2.4"/>),
      ~s(<rect x="8" y="197" width="120" height="2.4"/></g></svg>)
    ])
  end

  defp text(nil), do: ""
  defp text(text), do: text |> String.slice(0, 60) |> Plug.HTML.html_escape()

  defp mm(number), do: :erlang.float_to_binary(number / 1, decimals: 2)
end
