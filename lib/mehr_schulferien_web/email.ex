defmodule MehrSchulferienWeb.Email do
  import Bamboo.Email

  alias MehrSchulferienWeb.Mailer

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
end
