defmodule MehrSchulferienWeb.Shared.FormFieldComponent do
  @moduledoc """
  Shared form field components for consistent form styling across the application.
  Replaces duplicated form field patterns in LiveView templates.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :required, :boolean, default: false
  attr :type, :string, default: "text"
  attr :class, :string, default: ""

  def text_input(assigns) do
    ~H"""
    <div class="space-y-2">
      <label for={@id} class="block text-sm font-medium text-gray-700">
        <%= @label %>
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={@value}
        placeholder={@placeholder}
        required={@required}
        class={"block w-full rounded-lg border-2 border-slate-300 bg-white px-4 py-3 text-slate-700 placeholder-slate-400 focus:border-blue-500 focus:outline-none focus:ring-0 transition-colors #{@class}"}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :required, :boolean, default: false
  attr :rows, :integer, default: 4
  attr :class, :string, default: ""

  def textarea(assigns) do
    ~H"""
    <div class="space-y-2">
      <label for={@id} class="block text-sm font-medium text-gray-700">
        <%= @label %>
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <textarea
        id={@id}
        name={@name}
        placeholder={@placeholder}
        required={@required}
        rows={@rows}
        class={"block w-full rounded-lg border-2 border-slate-300 bg-white px-4 py-3 text-slate-700 placeholder-slate-400 focus:border-blue-500 focus:outline-none focus:ring-0 transition-colors resize-none #{@class}"}
      ><%= @value %></textarea>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :selected, :string, default: ""
  attr :required, :boolean, default: false
  attr :class, :string, default: ""

  def select(assigns) do
    ~H"""
    <div class="space-y-2">
      <label for={@id} class="block text-sm font-medium text-gray-700">
        <%= @label %>
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <select
        id={@id}
        name={@name}
        required={@required}
        class={"block w-full rounded-lg border-2 border-slate-300 bg-white px-4 py-3 text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-0 transition-colors #{@class}"}
      >
        <%= for {value, label} <- @options do %>
          <option value={value} selected={value == @selected}>
            <%= label %>
          </option>
        <% end %>
      </select>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :selected, :string, default: ""
  attr :required, :boolean, default: false

  def radio_group(assigns) do
    ~H"""
    <div class="space-y-3">
      <fieldset>
        <legend class="text-sm font-medium text-gray-700">
          <%= @label %>
          <%= if @required do %>
            <span class="text-red-500">*</span>
          <% end %>
        </legend>
        <div class="mt-2 space-y-2">
          <%= for {value, label} <- @options do %>
            <div class="flex items-center">
              <input
                id={"#{@name}_#{value}"}
                name={@name}
                type="radio"
                value={value}
                checked={value == @selected}
                required={@required}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
              />
              <label for={"#{@name}_#{value}"} class="ml-3 block text-sm text-gray-700">
                <%= label %>
              </label>
            </div>
          <% end %>
        </div>
      </fieldset>
    </div>
    """
  end
end
