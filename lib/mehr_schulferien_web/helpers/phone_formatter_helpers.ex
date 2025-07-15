defmodule MehrSchulferienWeb.Helpers.PhoneFormatterHelpers do
  @moduledoc """
  Web layer wrapper for phone formatting helpers.
  Delegates to core PhoneFormatter to avoid duplication.
  """

  alias MehrSchulferien.Helpers.PhoneFormatter

  defdelegate format_phone_number(phone_number), to: PhoneFormatter
  defdelegate format_tel_link(phone_number), to: PhoneFormatter
  defdelegate clean_phone_number(phone_number), to: PhoneFormatter
  defdelegate valid_phone_number?(phone_number), to: PhoneFormatter
  defdelegate format_international(phone_number), to: PhoneFormatter
end
