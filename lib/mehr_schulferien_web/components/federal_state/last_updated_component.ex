defmodule MehrSchulferienWeb.FederalState.LastUpdatedComponent do
  use Phoenix.Component

  attr :periods, :list, required: true
  attr :federal_state, :any, required: true

  def last_updated(assigns) do
    assigns = assign(assigns, :last_update, get_last_update_date(assigns.periods))

    ~H"""
    <%= if @last_update do %>
      <div class="text-xs text-gray-500 mt-4 flex items-center justify-end">
        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          >
          </path>
        </svg>
        <time datetime={@last_update} itemprop="dateModified">
          Zuletzt aktualisiert: <%= Calendar.strftime(@last_update, "%d.%m.%Y") %>
        </time>
        <meta itemprop="datePublished" content={@last_update} />
      </div>
    <% end %>
    """
  end

  defp get_last_update_date(periods) when is_list(periods) do
    case periods do
      [] ->
        nil

      periods ->
        periods
        |> Enum.map(& &1.updated_at)
        |> Enum.max_by(
          fn
            %NaiveDateTime{} = dt ->
              NaiveDateTime.to_erl(dt) |> :calendar.datetime_to_gregorian_seconds()

            %DateTime{} = dt ->
              DateTime.to_unix(dt)

            _ ->
              0
          end,
          fn -> nil end
        )
        |> case do
          %NaiveDateTime{} = dt -> NaiveDateTime.to_date(dt)
          %DateTime{} = dt -> DateTime.to_date(dt)
          _ -> nil
        end
    end
  end

  defp get_last_update_date(_), do: nil
end
