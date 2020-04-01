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
      from: "support@example.com",
      subject: "New period added",
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
    |> subject("Confirm email address")
    |> html_body(
      "<h3>Click on the link below to confirm this email address</h3><p><a href=#{link}>Confirm email</a></p>"
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
    |> subject("Reset your password")
    |> html_body(
      "<h3>Click on the link below to reset your password</h3><p><a href=#{link}>Password reset</a></p>"
    )
    |> Mailer.deliver_later()
  end

  @doc """
  An email acknowledging that the account has been successfully confirmed.
  """
  def confirm_success(address) do
    address
    |> base_email()
    |> subject("Confirmed account")
    |> text_body("Your account has been confirmed.")
    |> Mailer.deliver_later()
  end

  @doc """
  An email acknowledging that the password has been successfully reset.
  """
  def reset_success(address) do
    address
    |> base_email()
    |> subject("Password reset")
    |> text_body("Your password has been reset.")
    |> Mailer.deliver_later()
  end

  defp base_email(address) do
    new_email()
    |> to(address)
    |> from("admin@example.com")
  end
end
