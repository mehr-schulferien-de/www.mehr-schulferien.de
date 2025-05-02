defmodule MehrSchulferien.CountryNotParentError do
  defexception message: "Country is not a parent of the location", plug_status: 404
end

defmodule MehrSchulferien.InvalidQueryParamsError do
  defexception message: "Invalid query", plug_status: 404
end

defmodule MehrSchulferien.InvalidYearError do
  defexception message: "Invalid year", plug_status: 404
end

defmodule MehrSchulferien.NoHolidayOrVacationTypePeriod do
  defexception message: "Location has no period of the specified holiday_or_vacation_type",
               plug_status: 404
end
