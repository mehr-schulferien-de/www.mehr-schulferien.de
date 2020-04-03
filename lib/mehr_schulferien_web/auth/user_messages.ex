defmodule MehrSchulferienWeb.Auth.UserMessages do
  use Phauxth.UserMessages.Base

  def default_error,
    do: "Fehlerhafte Eingabe oder Sie haben Ihre E-Mail Adresse noch nicht bestätigt."
end
