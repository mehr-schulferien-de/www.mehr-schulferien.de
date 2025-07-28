defmodule MehrSchulferienWeb.Components.GitHubPromotionComponent do
  @moduledoc """
  Shared GitHub promotion component for document generation pages.
  Uses Tailwind CSS for styling.
  """
  use Phoenix.Component

  @doc """
  Renders GitHub promotion section with Tailwind CSS styling
  """
  attr :locale, :string, default: "de"
  attr :translate_fn, :any, required: false
  attr :wrapper_class, :string, default: nil

  def github_promotion(assigns) do
    # Default translate function if none provided
    assigns =
      assign_new(assigns, :translate_fn, fn ->
        fn key, locale ->
          translations = %{
            "Open Source & Participation" => %{
              "de" => "Open Source & Mitmachen",
              "en" => "Open Source & Participation",
              "ru" => "Открытый исходный код и участие",
              "ar" => "المصدر المفتوح والمشاركة",
              "tr" => "Açık Kaynak ve Katılım",
              "pl" => "Open Source i udział",
              "fr" => "Open Source et participation",
              "uk" => "Відкритий код та участь"
            },
            "This project is open source and thrives on community participation. Do you have feedback or feature requests (other forms or letters)? Visit us on GitHub and create an issue!" =>
              %{
                "de" =>
                  "Dieses Projekt ist Open Source und lebt von der Mithilfe der Community. Haben Sie Feedback oder Feature-Wünsche (andere Formulare oder Briefe)? Besuchen Sie uns auf GitHub und erstellen Sie ein Issue!",
                "en" =>
                  "This project is open source and thrives on community participation. Do you have feedback or feature requests (other forms or letters)? Visit us on GitHub and create an issue!",
                "ru" =>
                  "Этот проект с открытым исходным кодом процветает благодаря участию сообщества. У вас есть отзывы или запросы функций (другие формы или письма)? Посетите нас на GitHub и создайте issue!",
                "ar" =>
                  "هذا المشروع مفتوح المصدر ويزدهر بمشاركة المجتمع. هل لديك ملاحظات أو طلبات ميزات (نماذج أو رسائل أخرى)؟ قم بزيارتنا على GitHub وأنشئ issue!",
                "tr" =>
                  "Bu proje açık kaynaklıdır ve topluluk katılımıyla gelişir. Geri bildiriminiz veya özellik istekleriniz (diğer formlar veya mektuplar) var mı? GitHub'da bizi ziyaret edin ve bir issue oluşturun!",
                "pl" =>
                  "Ten projekt jest open source i rozwija się dzięki udziału społeczności. Masz opinię lub prośby o funkcje (inne formularze lub listy)? Odwiedź nas na GitHub i utwórz issue!",
                "fr" =>
                  "Ce projet est open source et prospère grâce à la participation de la communauté. Avez-vous des commentaires ou des demandes de fonctionnalités (autres formulaires ou lettres) ? Visitez-nous sur GitHub et créez un issue !",
                "uk" =>
                  "Цей проект з відкритим вихідним кодом процвітає завдяки участі спільноти. У вас є відгуки або запити функцій (інші форми або листи)? Відвідайте нас на GitHub і створіть issue!"
              },
            "Visit GitHub Project" => %{
              "de" => "GitHub-Projekt besuchen",
              "en" => "Visit GitHub Project",
              "ru" => "Посетить проект на GitHub",
              "ar" => "زيارة مشروع GitHub",
              "tr" => "GitHub Projesini Ziyaret Et",
              "pl" => "Odwiedź projekt GitHub",
              "fr" => "Visiter le projet GitHub",
              "uk" => "Відвідати проект на GitHub"
            }
          }

          case translations[key] do
            %{} = trans -> Map.get(trans, locale, trans["de"] || key)
            _ -> key
          end
        end
      end)

    ~H"""
    <div class={@wrapper_class || "px-6 py-8 sm:px-8 border-t border-slate-200 dark:border-slate-700"}>
      <div class="max-w-2xl mx-auto text-center">
        <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 dark:bg-slate-700 mb-4">
          <svg
            class="w-6 h-6 text-slate-600 dark:text-slate-300"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              fill-rule="evenodd"
              d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">
          {@translate_fn.("Open Source & Participation", @locale)}
        </h3>
        <p class="text-slate-600 dark:text-slate-300 mb-4">
          {@translate_fn.(
            "This project is open source and thrives on community participation. Do you have feedback or feature requests (other forms or letters)? Visit us on GitHub and create an issue!",
            @locale
          )}
        </p>
        <a
          href="https://github.com/mehr-schulferien-de/www.mehr-schulferien.de"
          class="inline-flex items-center px-4 py-2 border border-slate-300 dark:border-slate-600 shadow-sm text-sm font-medium rounded-lg text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-slate-800 transition-colors"
          target="_blank"
          rel="noopener noreferrer"
        >
          <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24">
            <path
              fill-rule="evenodd"
              d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
              clip-rule="evenodd"
            />
          </svg>
          {@translate_fn.("Visit GitHub Project", @locale)}
        </a>
      </div>
    </div>
    """
  end
end
