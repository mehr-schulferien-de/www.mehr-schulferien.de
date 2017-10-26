# mix ExportRedirects

defmodule Mix.Tasks.ExportRedirects do
  use Mix.Task

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Locations.School
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.InsetDayQuantity
  alias MehrSchulferien.Timetables.Category
  alias MehrSchulferien.Repo
  alias MehrSchulferien.CollectData
  import Ecto.Query, only: [from: 2]

  @shortdoc "Exports Nginx Redirect rules"
  def run(_args) do
    Mix.Task.run "app.start"
    Mix.shell.info "# Here is the config for nginx:"

    federal_states = Locations.list_federal_states

    for federal_state <- federal_states do
      year = 2018
      IO.puts "rewrite ^/federal_states/"<>federal_state.slug<>"/years/"<>Integer.to_string(year)<>"$ https://www.mehr-schulferien.de/federal_states/"<>federal_state.slug<>"/"<>Integer.to_string(year)<>"-01-01/"<>Integer.to_string(year)<>"-12-31 redirect;"
      IO.puts "rewrite ^/federal_states/"<>federal_state.slug<>"/years/"<>Integer.to_string(year)<>".html$ https://www.mehr-schulferien.de/federal_states/"<>federal_state.slug<>"/"<>Integer.to_string(year)<>"-01-01/"<>Integer.to_string(year)<>"-12-31 redirect;"
    end

    schools = Locations.list_schools

    for school <- schools do
      if school.old_slug != nil do
        IO.puts "rewrite ^/schools/"<>school.old_slug<>".html$ https://www.mehr-schulferien.de/schools/"<>school.slug<>" redirect;"
      end
    end

  end
end
