defmodule MehrSchulferienWeb.LocalePlug do
  @moduledoc """
  Plug for setting the locale based on browser Accept-Language header
  or session preferences.
  """
  import Plug.Conn

  @supported_locales ~w(de en ru ar tr pl fr uk)
  @default_locale "de"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = get_locale(conn)
    Gettext.put_locale(MehrSchulferienWeb.Gettext, locale)

    # Store locale in session if it came from URL parameter
    conn =
      if conn.params["locale"] && validate_locale(conn.params["locale"]) do
        put_session(conn, :locale, locale)
      else
        conn
      end

    assign(conn, :locale, locale)
  end

  defp get_locale(conn) do
    # Priority: 
    # 1. URL parameter "locale"
    # 2. Session "locale" 
    # 3. Browser Accept-Language header
    # 4. Default locale

    cond do
      # Check URL parameter
      locale = conn.params["locale"] && validate_locale(conn.params["locale"]) ->
        locale

      # Check session
      locale = get_session(conn, :locale) && validate_locale(get_session(conn, :locale)) ->
        locale

      # Check browser Accept-Language header
      locale = get_browser_locale(conn) ->
        locale

      # Fallback to default
      true ->
        @default_locale
    end
  end

  defp validate_locale(locale) when locale in @supported_locales, do: locale
  defp validate_locale(_), do: nil

  defp get_browser_locale(conn) do
    case get_req_header(conn, "accept-language") do
      [accept_language | _] ->
        accept_language
        |> String.split(",")
        |> Enum.map(&parse_language_tag/1)
        |> Enum.sort_by(&elem(&1, 1), :desc)
        |> Enum.find_value(fn {lang, _weight} ->
          find_supported_locale(lang)
        end)

      _ ->
        nil
    end
  end

  defp parse_language_tag(tag) do
    case String.split(tag, ";") do
      [lang] ->
        {String.trim(lang), 1.0}

      [lang, quality] ->
        weight =
          quality
          |> String.trim()
          |> String.replace("q=", "")
          |> String.to_float()

        {String.trim(lang), weight}
    end
  rescue
    _ -> {String.trim(tag), 1.0}
  end

  defp find_supported_locale(browser_lang) do
    # First try exact match
    if browser_lang in @supported_locales do
      browser_lang
    else
      # Try language part only (e.g., "en-US" -> "en")
      lang_part =
        case String.split(browser_lang, "-") do
          [first | _] -> first
          [] -> browser_lang
        end

      if lang_part in @supported_locales do
        lang_part
      else
        nil
      end
    end
  end

  def supported_locales, do: @supported_locales
  def default_locale, do: @default_locale
end
