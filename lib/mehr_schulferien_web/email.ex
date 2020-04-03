defmodule MehrSchulferienWeb.Email do
  import Bamboo.Email

  alias MehrSchulferienWeb.Mailer

  @doc """
  Sends an email notifying the administrator that a period has been added.
  """
  def period_added_notification(details) do
    text = encode_data(details)

    new_email(
      to: "sw@wintermeyer-consulting.de",
      from: "do-not-reply@mehr-schulferien.de",
      subject: "Neuer Termin wurde eingetragen",
      text_body: text
    )
    |> Mailer.deliver_later()
  end

  defp encode_data(%MehrSchulferien.Calendars.Period{
         created_by_email_address: email,
         starts_on: starts_on,
         ends_on: ends_on
       }) do
    Jason.encode!(%{created_by_email_address: email, starts_on: starts_on, ends_on: ends_on})
  end

  @doc """
  An email with a confirmation link in it.
  """
  def confirm_request(address, link) do
    address
    |> base_email()
    |> subject("E-Mail Adresse für mehr-schulferien.de Account bestätigen")
    |> html_body(
      "<p>Bitte bestätigen Sie mit einem Klick auf diesen Link Ihre E-Mail Adresse für Ihren mehr-schulferien.de Account.</p><p><a href=#{
        link
      }>E-Mail Adresse bestätigen.</a></p>"
    )
    |> Mailer.deliver_later()
  end

  @doc """
  An email with a link to reset the password.
  """
  def reset_request(address, nil) do
    address
    |> base_email()
    |> subject("Reset your password")
    |> text_body(
      "You requested a password reset, but no user is associated with the email you provided."
    )
    |> Mailer.deliver_later()
  end

  def reset_request(address, link) do
    address
    |> base_email()
    |> subject("Passwort zurücksetzen")
    |> html_body(
      "<p>Bitte bestätigen Sie mit einem Klick auf diesen Link das Sie Ihr Passwort auf mehr-schulferien.de zurücksetzen wollen.</p><p><a href=#{
        link
      }>Passwort zurücksetzen.</a></p>"
    )
    |> Mailer.deliver_later()
  end

  @doc """
  An email acknowledging that the account has been successfully confirmed.
  """
  def confirm_success(address) do
    address
    |> base_email()
    |> subject("mehr-schulferien.de Account-Bestätigung")
    |> html_body(
      "<p>Ihr Account für https://www.mehr-schulferien.de wurde freigeschaltet.</p><p>Vielen Dank für Ihre Hilfe!</p>"
    )
    |> Mailer.deliver_later()
  end

  @doc """
  An email acknowledging that the password has been successfully reset.
  """
  def reset_success(address) do
    address
    |> base_email()
    |> subject("Passwort reset")
    |> text_body("Ihr Passwort wurde zurückgesetzt.")
    |> Mailer.deliver_later()
  end

  defp base_email(address) do
    new_email()
    |> to(address)
    |> from("sw@wintermeyer-consulting.de")
  end
end
