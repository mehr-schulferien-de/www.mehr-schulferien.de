# Generated seed file for religions
# This file was automatically generated from the database

religions_data = [
  %{
    name: "Christentum",
    updated_at: ~N[2020-03-20 09:58:27],
    slug: "christentum",
    inserted_at: ~N[2020-03-20 09:58:27],
    wikipedia_url: "https://de.wikipedia.org/wiki/Christentum"
  },
  %{
    name: "Judentum",
    updated_at: ~N[2020-03-20 09:58:27],
    slug: "judentum",
    inserted_at: ~N[2020-03-20 09:58:27],
    wikipedia_url: "https://de.wikipedia.org/wiki/Judentum"
  },
  %{
    name: "Islam",
    updated_at: ~N[2020-03-20 09:58:27],
    slug: "islam",
    inserted_at: ~N[2020-03-20 09:58:27],
    wikipedia_url: "https://de.wikipedia.org/wiki/Islam"
  }
]

# Initialize lookup maps
religion_lookup = %{}

# Create lookup map for religions by slug
{_, religion_results} = MehrSchulferien.Repo.insert_all("religions", religions_data, returning: [:id, :slug])
religion_lookup = Map.merge(religion_lookup, Map.new(religion_results, fn %{id: id, slug: slug} -> {slug, id} end))
Process.put(:religion_lookup, religion_lookup)

IO.puts("Inserted #{length(religions_data)} religions")
