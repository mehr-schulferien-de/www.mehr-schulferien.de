# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Import all seed files in the correct order

IO.puts("Starting seed import...")

# Initialize lookup maps for cross-file references
religion_lookup = %{}
location_lookup = %{}
holiday_type_lookup = %{}
zip_code_lookup = %{}

# Import in dependency order
Code.require_file("religions.exs", "priv/repo/seeds")
Code.require_file("locations.exs", "priv/repo/seeds")
Code.require_file("holiday_or_vacation_types.exs", "priv/repo/seeds")
Code.require_file("zip_codes.exs", "priv/repo/seeds")
Code.require_file("zip_code_mappings.exs", "priv/repo/seeds")
Code.require_file("addresses.exs", "priv/repo/seeds")
Code.require_file("periods.exs", "priv/repo/seeds")

IO.puts("All seeds imported successfully!")
