defmodule MehrSchulferien.Repo.Migrations.FixDataEntySommerferienBayern2018 do
  use Ecto.Migration
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Period
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  def up do
    # This fixes a bug in the original data set:
    # https://github.com/wintermeyer/www.mehr-schulferien.de/issues/3
    #
    query = from fs in FederalState, where: fs.slug == "bayern"
    federal_state = Repo.one(query)
      if federal_state != nil do
      query = from p in Period, where: p.starts_on == ^~D[2018-07-05] and
                                       p.ends_on == ^~D[2018-08-17] and
                                       p.federal_state_id == ^federal_state.id and
                                       p.name == "Sommer"
      period = Repo.one(query)

      if period != nil do
        period = Repo.one(query)
        Timetables.delete_period(period)
        category = MehrSchulferien.Timetables.get_category!("schulferien")
        Timetables.create_period(%{
                                     starts_on: ~D[2018-07-30],
                                     source: "https://www.kmk.org/service/ferien.html",
                                     name: "Sommer",
                                     federal_state_id: federal_state.id,
                                     ends_on: ~D[2018-09-10],
                                     category_id: category.id
                                   })

      end
    end
  end

#  {"starts_on":"2018-07-30","source":"https://www.kmk.org/service/ferien.html","school_slug":null,"name":"Sommer","federal_state_slug":"bayern","ends_on":"2018-09-10","country_slug":null,"city_slug":null,"category":"Schulferien"}


  def down do

  end
end
