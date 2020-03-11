defmodule MehrSchulferien.CountryNotParentError do
  defexception message: "Country is not a parent of the location", plug_status: 404
end
