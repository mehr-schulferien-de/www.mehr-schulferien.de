defmodule MehrSchulferienWeb.Components.Faq.FaqSchemaComponent do
  @moduledoc """
  Handles schema.org FAQ markup generation.
  """

  use Phoenix.Component
  alias MehrSchulferienWeb.Helpers.JsonHelpers

  attr :faq_data, :map, required: true
  attr :is_school_page, :boolean, required: true

  def faq_schema(assigns) do
    # Filter out holiday questions if location is a school
    filtered_questions =
      if assigns.is_school_page do
        Enum.reject(assigns.faq_data.all_questions, fn question ->
          Enum.member?(assigns.faq_data.holiday_questions, question) ||
            question == assigns.faq_data.next_holiday_question
        end)
      else
        assigns.faq_data.all_questions
      end

    # Filter out questions with empty answers and properly format for JSON
    valid_questions =
      filtered_questions
      |> Enum.filter(fn question ->
        question && question.answer && String.trim(question.answer) != ""
      end)
      |> Enum.map(fn question ->
        %{
          title: question.title,
          answer: JsonHelpers.strip_html_and_escape(question.answer)
        }
      end)

    # Only render if we have valid questions
    if valid_questions != [] do
      assigns = assign(assigns, :valid_questions, valid_questions)

      ~H"""
      <script type="application/ld+json">
        <%= Phoenix.HTML.raw(Jason.encode!(%{
          "@context" => "https://schema.org",
          "@type" => "FAQPage",
          "mainEntity" => Enum.map(@valid_questions, fn question ->
            %{
              "@type" => "Question",
              "name" => question.title,
              "acceptedAnswer" => %{
                "@type" => "Answer",
                "text" => question.answer
              }
            }
          end)
        })) %>
      </script>
      """
    else
      ~H""
    end
  end
end
