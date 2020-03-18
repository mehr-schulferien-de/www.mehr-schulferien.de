defmodule MehrSchulferienWeb.EmailTest do
  use MehrSchulferien.DataCase
  use Bamboo.Test

  import MehrSchulferien.Factory

  alias MehrSchulferienWeb.Email

  test "email is sent when user adds a period" do
    period = insert(:period)
    sent_email = Email.period_added_notification(period)
    assert sent_email.subject =~ "New period added"
    assert sent_email.text_body =~ ~s("created_by_email_address":"sw@wintermeyer-consulting.de")
  end
end
