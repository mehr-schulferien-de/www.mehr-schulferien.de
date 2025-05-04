defmodule MehrSchulferienWeb.TimelineLegendComponent do
  use Phoenix.Component

  @doc """
  Renders a legend for timeline items with color codes.

  ## Examples
      <.timeline_legend
        items={[
          %{color: "bg-purple-600", label: "Brückentag (01.05.)"},
          %{color: "bg-blue-600", label: "Feiertag (03.05.)"}
        ]}
      />
  """
  attr :items, :list, required: true, doc: "List of items to show in the legend"
  attr :class, :string, default: "mt-4", doc: "Additional CSS classes"

  def timeline_legend(assigns) do
    ~H"""
    <ul class={["text-sm space-y-1", @class]}>
      <%= for item <- @items do %>
        <li class="flex items-center space-x-3">
          <div class={[item.color, "w-4 h-4 flex-shrink-0"]}></div>
          <span><%= item.label %></span>
        </li>
      <% end %>
    </ul>
    """
  end
end
