defmodule MehrSchulferienWeb.Auth.UserMessages do
  use Phauxth.UserMessages.Base

  def default_error, do: "Invalid credentials or you have not confirmed your account yet"
end
