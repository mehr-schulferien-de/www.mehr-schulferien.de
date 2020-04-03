defmodule MehrSchulferienWeb.ConfirmController do
  use MehrSchulferienWeb, :controller

  alias Phauxth.Confirm
  alias MehrSchulferien.Accounts
  alias MehrSchulferienWeb.Email

  def index(conn, params) do
    case Confirm.verify(params) do
      {:ok, user} ->
        Accounts.confirm_user(user)
        Email.confirm_success(user.email)

        conn
        |> put_flash(:info, "Ihr Account wurde freigeschaltet. Bitte loggen Sie sich jetzt ein.")
        |> redirect(to: Routes.session_path(conn, :new))

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end
end
