# Imports l'tur affiliate marketing data.
#
# mix ImportLturData

defmodule Mix.Tasks.ImportLturData do
  use Mix.Task

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Airport
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.TravelOffer
  alias MehrSchulferien.Repo
  import Ecto.Query

  @shortdoc "Fetches and imports l'tur affiliate marketing data."
  def run(_args) do
    Mix.Task.run "app.start"
    # Mix.shell.info "# Here is the config for nginx:"

    tour_operator = "l'tur"

    # Delete old entries
    #
    from(to in TravelOffer, where: to.tour_operator == ^tour_operator) |> Repo.delete_all

    url = "http://productdata.zanox.com/exportservice/v1/rest/43967799C752948137.csv?ticket=891A48AB858AD73FAFE1447C86CEABD1&productIndustryId=2&columnDelimiter=,&textQualifier=DoubleQuote&nullOutputFormat=NullValue&dateFormat=yyyy-MM-dd'T'HH:mm:ss:SSS&decimalSeparator=period&id=&pg=&nb=&na=&pp=&po=&cy=&du=&ds=&dl=&tm=&mc=&c1=&c2=&c3=&ia=&im=&il=&df=&dt=&lk=&ss=&sa=&af=&sp=&sv=&x1=&x2=&x3=&x4=&x5=&x6=&x7=&x8=&x9=&zi=&fd=&to=&dn=&da=&dz=&dc=&dy=&dr=&dp=&do=&tu=&ti=&ta=&tr=&tt=&tp=&p3=&gZipCompress=null"

    body = HTTPoison.get!(url).body |> :unicode.characters_to_list |> Enum.drop(1) |> :erlang.list_to_binary

    filename = "/tmp/ltur-data.csv"
    File.rm(filename)
    File.write!(filename, body)
    data = filename |> File.stream! |> CSV.decode!(headers: true) |> Enum.to_list
    File.rm(filename)

    for product <- data do
      airport_name = case product["ExtraTextOne"] |> String.split("Origin: ") |> List.last |> String.trim do
        "Frankfurt" -> "Frankfurt am Main"
        "Köln-Bonn" -> "Köln/Bonn"
        "Berlin Tegel" -> "Berlin-Tegel"
        "Berlin Schönefeld" -> "Berlin-Schönefeld"
        "Hannover" -> "Hannover-Langenhagen"
        "Erfurt" -> "Erfurt-Weimar"
        x -> x
      end

      query = from a in Airport, where: a.name == ^airport_name
      airport = Repo.one(query)

      %URI{query: url_query} = URI.parse(product["ZanoxProductLink"])

      duration = for query_element <- url_query |> String.split("&") do
        case query_element |> String.replace(~r/.*\?/,"") |> String.split("=") do
          ["duration", value] -> value
          _ -> nil
        end
      end |> Enum.filter(& !is_nil(&1)) |> List.first |> String.to_integer

      if airport != nil do
        unless (product["DestinationName"] |> String.match?(~r/dult/)) do # no adult only offers
          Ads.create_travel_offer(%{
            destination_name: product["DestinationName"],
            product_name: String.replace(product["ProductName"], "&Umgebung", "& Umgebung"),
            product_price: String.to_float(product["ProductPrice"]),
            product_link: product["ZanoxProductLink"],
            image_url: product["ImageLargeURL"],
            duration: duration,
            ad_middleman: "Zanox",
            tour_operator: tour_operator,
            expires_on: Date.add(Date.utc_today, 30),
            airport_id: airport.id
            })
        end
      end
    end

  end
end
