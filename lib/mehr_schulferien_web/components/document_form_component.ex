defmodule MehrSchulferienWeb.Components.DocumentFormComponent do
  @moduledoc """
  Shared form components for document generation (Entschuldigung, Beurlaubung, Sportbefreiung)
  """
  use Phoenix.Component

  @doc """
  Renders the sender information section
  """
  attr :form_data, :map, required: true
  attr :locale, :string, required: true
  attr :translate_fn, :any, required: true

  def sender_section(assigns) do
    ~H"""
    <fieldset class="border border-gray-300 rounded-lg p-6 mb-6">
      <legend class="text-lg font-semibold px-2">
        <%= @translate_fn.("Sender", @locale) %>
      </legend>
      <p class="text-sm text-gray-600 mb-4">
        <%= @translate_fn.("Your personal information for the excuse letter", @locale) %>
      </p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Title (optional)", @locale) %>
          </label>
          <input
            type="text"
            id="title"
            name="form[title]"
            value={@form_data.title}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            placeholder="Dr., Prof., etc."
            phx-change="validate"
          />
        </div>
        <div>
          <label for="first_name" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("First Name", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="first_name"
            name="form[first_name]"
            value={@form_data.first_name}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="last_name" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Last Name", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="last_name"
            name="form[last_name]"
            value={@form_data.last_name}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div class="md:col-span-2">
          <label for="street" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Street and House Number (optional)", @locale) %>
          </label>
          <input
            type="text"
            id="street"
            name="form[street]"
            value={@form_data.street}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="zip_code" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("ZIP Code", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="zip_code"
            name="form[zip_code]"
            value={@form_data.zip_code}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="city" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("City", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="city"
            name="form[city]"
            value={@form_data.city}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
      </div>
    </fieldset>
    """
  end

  @doc """
  Renders the school and student information section
  """
  attr :form_data, :map, required: true
  attr :locale, :string, required: true
  attr :translate_fn, :any, required: true
  attr :teacher_label, :string, default: "Class Teacher"

  def student_section(assigns) do
    ~H"""
    <fieldset class="border border-gray-300 rounded-lg p-6 mb-6">
      <legend class="text-lg font-semibold px-2">
        <%= @translate_fn.("School and Student Information", @locale) %>
      </legend>
      <p class="text-sm text-gray-600 mb-4">
        <%= @translate_fn.("Information about the school and student", @locale) %>
      </p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label for="teacher_salutation" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("#{@teacher_label} Salutation", @locale) %>
          </label>
          <select
            id="teacher_salutation"
            name="form[teacher_salutation]"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          >
            <option value="Herr" selected={@form_data.teacher_salutation == "Herr"}>
              <%= @translate_fn.("Mr.", @locale) %>
            </option>
            <option value="Frau" selected={@form_data.teacher_salutation == "Frau"}>
              <%= @translate_fn.("Ms.", @locale) %>
            </option>
          </select>
        </div>
        <div>
          <label for="teacher_name" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("#{@teacher_label} Name", @locale) %>
          </label>
          <input
            type="text"
            id="teacher_name"
            name="form[teacher_name]"
            value={@form_data.teacher_name}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="name_of_student" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Student Name", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="name_of_student"
            name="form[name_of_student]"
            value={@form_data.name_of_student}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="class_name" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Class", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="class_name"
            name="form[class_name]"
            value={@form_data.class_name}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            placeholder="5a, 10b, etc."
            phx-change="validate"
          />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-2">
            <%= @translate_fn.("My relationship to the student:", @locale) %>
          </label>
          <div class="space-y-2">
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="form[child_type]"
                value="mein_sohn"
                checked={@form_data.child_type == "mein_sohn"}
                class="mr-2 text-blue-600 focus:ring-blue-500"
                phx-change="validate"
              />
              <span><%= @translate_fn.("my son", @locale) %></span>
            </label>
            <br />
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="form[child_type]"
                value="meine_tochter"
                checked={@form_data.child_type == "meine_tochter"}
                class="mr-2 text-blue-600 focus:ring-blue-500"
                phx-change="validate"
              />
              <span><%= @translate_fn.("my daughter", @locale) %></span>
            </label>
            <br />
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="form[child_type]"
                value="sonstiges"
                checked={@form_data.child_type == "sonstiges"}
                class="mr-2 text-blue-600 focus:ring-blue-500"
                phx-change="validate"
              />
              <span>
                <%= @translate_fn.("neither son nor daughter, but I have custody", @locale) %>
              </span>
            </label>
          </div>
        </div>
      </div>
    </fieldset>
    """
  end

  @doc """
  Renders the date selection fields
  """
  attr :form_data, :map, required: true
  attr :locale, :string, required: true
  attr :translate_fn, :any, required: true
  attr :single_date, :boolean, default: false
  attr :duration_type, :boolean, default: false

  def date_section(assigns) do
    ~H"""
    <%= if @duration_type do %>
      <div class="mb-4">
        <label class="block text-sm font-medium text-gray-700 mb-2">
          <%= @translate_fn.("Duration Type:", @locale) %>
        </label>
        <div class="space-y-2">
          <label class="inline-flex items-center">
            <input
              type="radio"
              name="form[duration_type]"
              value="single_lesson"
              checked={@form_data.duration_type == "single_lesson"}
              class="mr-2 text-blue-600 focus:ring-blue-500"
              phx-change="validate"
            />
            <span><%= @translate_fn.("Single sports lesson", @locale) %></span>
          </label>
          <br />
          <label class="inline-flex items-center">
            <input
              type="radio"
              name="form[duration_type]"
              value="period"
              checked={@form_data.duration_type == "period"}
              class="mr-2 text-blue-600 focus:ring-blue-500"
              phx-change="validate"
            />
            <span><%= @translate_fn.("Period of time", @locale) %></span>
          </label>
        </div>
      </div>
    <% end %>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <%= if @single_date and @form_data[:duration_type] == "single_lesson" do %>
        <div class="md:col-span-2">
          <label for="single_date" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Date", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="date"
            id="single_date"
            name="form[single_date]"
            value={@form_data.single_date}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
      <% else %>
        <div>
          <label for="start_date" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("Start Date", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="date"
            id="start_date"
            name="form[start_date]"
            value={@form_data.start_date}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
        <div>
          <label for="end_date" class="block text-sm font-medium text-gray-700 mb-1">
            <%= @translate_fn.("End Date", @locale) %> <span class="text-red-500">*</span>
          </label>
          <input
            type="date"
            id="end_date"
            name="form[end_date]"
            value={@form_data.end_date}
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            phx-change="validate"
          />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the download button
  """
  attr :locale, :string, required: true
  attr :translate_fn, :any, required: true

  def download_button(assigns) do
    ~H"""
    <div class="mt-6 flex justify-center">
      <button
        type="submit"
        phx-click="save"
        class="inline-flex items-center px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
      >
        <svg
          class="w-5 h-5 mr-2"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          >
          </path>
        </svg>
        <%= @translate_fn.("Download PDF", @locale) %>
      </button>
    </div>
    """
  end
end
