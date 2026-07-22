# Spam domain patterns seed script
#
# Run with: mix run priv/repo/seeds/spam_domains.exs
#
# These patterns block common spam domains from being added to school data.

alias MehrSchulferien.Repo
alias MehrSchulferien.Blacklist.Entry

spam_patterns = [
  # Adult content sites
  {"*onlyfans*", "homepage_url", "Adult content site"},
  {"*onlyfans*", "instagram_url", "Adult content site"},
  {"*pornhub*", "homepage_url", "Adult content site"},
  {"*xvideos*", "homepage_url", "Adult content site"},
  {"*xhamster*", "homepage_url", "Adult content site"},
  {"*redtube*", "homepage_url", "Adult content site"},
  {"*youporn*", "homepage_url", "Adult content site"},
  {"*brazzers*", "homepage_url", "Adult content site"},

  # Gambling sites
  {"*casino*", "homepage_url", "Gambling site"},
  {"*bet365*", "homepage_url", "Gambling site"},
  {"*betway*", "homepage_url", "Gambling site"},
  {"*pokerstars*", "homepage_url", "Gambling site"},
  {"*888casino*", "homepage_url", "Gambling site"},
  {"*slots*", "homepage_url", "Gambling site"},

  # Crypto/scam sites
  {"*bitcoin-profit*", "homepage_url", "Crypto scam site"},
  {"*crypto-millionaire*", "homepage_url", "Crypto scam site"},
  {"*immediate-edge*", "homepage_url", "Crypto scam site"},

  # Common spam patterns
  {"*free-iphone*", "homepage_url", "Spam site"},
  {"*win-a-prize*", "homepage_url", "Spam site"},
  {"*click-here*", "homepage_url", "Spam site"},
  {"*bit.ly/*", "homepage_url", "URL shortener (not allowed for official sites)"},
  {"*tinyurl.com/*", "homepage_url", "URL shortener (not allowed for official sites)"},

  # Dating sites
  {"*tinder*", "homepage_url", "Dating site"},
  {"*dating*", "homepage_url", "Dating site"},

  # Malware/phishing patterns
  {"*.xyz", "homepage_url", "Suspicious TLD"},
  {"*.tk", "homepage_url", "Suspicious TLD"},
  {"*.ml", "homepage_url", "Suspicious TLD"},
  {"*.ga", "homepage_url", "Suspicious TLD"},
  {"*.cf", "homepage_url", "Suspicious TLD"}
]

system_requester = "system@mehr-schulferien.de"
system_name = "System (Spam-Filter)"

IO.puts("Seeding spam domain patterns...")

Enum.each(spam_patterns, fn {pattern, field_type, reason} ->
  # Check if pattern already exists for this field type
  existing =
    Repo.get_by(Entry, pattern: pattern, field_type: field_type, is_active: true)

  if existing do
    IO.puts("  Skipping existing pattern: #{pattern} for #{field_type}")
  else
    case Repo.insert(
           Entry.create_changeset(%{
             pattern: pattern,
             field_type: field_type,
             reason: reason,
             full_name: system_name,
             email: system_requester
           })
         ) do
      {:ok, _entry} ->
        IO.puts("  Added: #{pattern} for #{field_type}")

      {:error, changeset} ->
        IO.puts("  Error adding #{pattern}: #{inspect(changeset.errors)}")
    end
  end
end)

IO.puts("Done! Added spam domain patterns to blacklist.")
