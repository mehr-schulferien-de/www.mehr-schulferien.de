defmodule MehrSchulferienWeb.WikiApprovalController do
  @moduledoc """
  Controller for handling wiki change approval and rejection via magic links.

  These endpoints are accessed by admins clicking links in notification emails.
  No authentication is required since the links contain unique tokens.
  """

  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Wiki.PendingChanges

  @doc """
  Handles approval of a pending change via magic link.

  GET /wiki/approve/:token
  """
  def approve(conn, %{"token" => token}) do
    case PendingChanges.get_by_approval_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Ungültiger oder abgelaufener Link.")
        |> render(:error, message: "Ungültiger oder abgelaufener Link.")

      %{status: "pending"} = pending_change ->
        case PendingChanges.approve_change!(pending_change) do
          {:ok, _result} ->
            conn
            |> put_flash(:info, "Änderung wurde erfolgreich genehmigt und angewendet.")
            |> render(:success,
              action: :approved,
              change_type: pending_change.change_type,
              message:
                "Die Änderung wurde erfolgreich genehmigt und auf der Live-Seite angewendet."
            )

          {:error, reason} ->
            conn
            |> put_flash(:error, "Fehler beim Anwenden der Änderung: #{inspect(reason)}")
            |> render(:error, message: "Fehler beim Anwenden der Änderung: #{inspect(reason)}")
        end

      %{status: status} ->
        message =
          case status do
            "approved" -> "Diese Änderung wurde bereits genehmigt."
            "rejected" -> "Diese Änderung wurde bereits abgelehnt."
            _ -> "Diese Änderung kann nicht mehr bearbeitet werden."
          end

        conn
        |> put_flash(:info, message)
        |> render(:already_processed, status: status, message: message)
    end
  end

  @doc """
  Handles rejection of a pending change via magic link.

  GET /wiki/reject/:token
  """
  def reject(conn, %{"token" => token}) do
    case PendingChanges.get_by_rejection_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Ungültiger oder abgelaufener Link.")
        |> render(:error, message: "Ungültiger oder abgelaufener Link.")

      %{status: "pending"} = pending_change ->
        case PendingChanges.reject_change!(pending_change) do
          {:ok, _result} ->
            conn
            |> put_flash(:info, "Änderung wurde abgelehnt.")
            |> render(:success,
              action: :rejected,
              change_type: pending_change.change_type,
              message: "Die Änderung wurde abgelehnt. Der Benutzer wird nicht benachrichtigt."
            )

          {:error, reason} ->
            conn
            |> put_flash(:error, "Fehler beim Ablehnen der Änderung: #{inspect(reason)}")
            |> render(:error, message: "Fehler beim Ablehnen der Änderung: #{inspect(reason)}")
        end

      %{status: status} ->
        message =
          case status do
            "approved" -> "Diese Änderung wurde bereits genehmigt."
            "rejected" -> "Diese Änderung wurde bereits abgelehnt."
            _ -> "Diese Änderung kann nicht mehr bearbeitet werden."
          end

        conn
        |> put_flash(:info, message)
        |> render(:already_processed, status: status, message: message)
    end
  end
end
