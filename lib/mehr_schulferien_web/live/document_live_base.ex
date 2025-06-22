defmodule MehrSchulferienWeb.DocumentLiveBase do
  @moduledoc """
  Base module for document LiveViews (Entschuldigung, Beurlaubung, Sportbefreiung).
  Provides shared functionality to reduce duplication.
  """

  defmacro __using__(opts) do
    document_type = Keyword.fetch!(opts, :document_type)

    quote do
      use MehrSchulferienWeb, :live_view
      import Phoenix.HTML

      alias MehrSchulferien.Locations
      alias MehrSchulferienWeb.Live.Shared.BriefeHelpers

      @document_type unquote(document_type)

      @impl true
      def mount(%{"school_slug" => school_slug} = params, session, socket) do
        # Get school and location hierarchy
        school_data = BriefeHelpers.fetch_school_data(school_slug)

        # Setup locale
        locale = BriefeHelpers.setup_locale(params, session, socket)

        # Initialize form with default values
        form_data = get_default_form_data()

        # Get page title
        page_title = get_page_title(school_data.school.name)

        {:ok,
         socket
         |> assign(school_data)
         |> assign(
           form_data: form_data,
           page_title: page_title,
           locale: locale,
           document_type: @document_type
         )}
      end

      @impl true
      def handle_event("validate", %{"form" => params}, socket) do
        form_data =
          socket.assigns.form_data
          |> Map.merge(BriefeHelpers.atomize_keys(params))
          |> BriefeHelpers.maybe_parse_dates(get_date_fields())

        {:noreply, assign(socket, form_data: form_data)}
      end

      @impl true
      def handle_event("save", %{"form" => params}, socket) do
        form_data =
          socket.assigns.form_data
          |> Map.merge(BriefeHelpers.atomize_keys(params))
          |> BriefeHelpers.maybe_parse_dates(get_date_fields())

        # Validate required fields
        case BriefeHelpers.validate_form_data(form_data, get_required_fields()) do
          :ok ->
            # Generate PDF download URL
            pdf_url =
              BriefeHelpers.build_pdf_url(socket.assigns.school.slug, form_data, @document_type)

            {:noreply,
             socket
             |> assign(form_data: form_data)
             |> put_flash(:info, BriefeHelpers.pdf_success_message())
             |> push_event("open_pdf", %{url: pdf_url})}

          {:error, message} ->
            {:noreply,
             socket
             |> assign(form_data: form_data)
             |> put_flash(:error, message)}
        end
      end

      @impl true
      def handle_info({:change_locale, locale}, socket) do
        {:noreply, BriefeHelpers.handle_locale_change(socket, locale, @document_type)}
      end

      # Translation helpers
      defp translate(key, locale) do
        translations = get_translations()

        case translations[key] do
          %{} = translation_map ->
            translation_map[locale] || translation_map["en"] || key

          nil ->
            # Check common translations
            common_translations = get_common_translations()

            case common_translations[key] do
              %{} = translation_map ->
                translation_map[locale] || translation_map["en"] || key

              nil ->
                key
            end
        end
      end

      defp translate(key, locale, bindings) when is_map(bindings) do
        translated = translate(key, locale)

        result =
          Enum.reduce(bindings, translated, fn {k, v}, acc ->
            value_string =
              case v do
                {:safe, content} -> content
                _ -> to_string(v)
              end

            String.replace(acc, "%{#{k}}", value_string)
          end)

        # If any of the bindings contain HTML (safe content), mark the result as safe
        if Enum.any?(bindings, fn {_, v} -> match?({:safe, _}, v) end) do
          raw(result)
        else
          result
        end
      end

      # Common translations shared by all document types
      defp get_common_translations do
        %{
          "For %{school_name}" => %{
            "de" => "Für %{school_name}",
            "en" => "For %{school_name}",
            "ru" => "Для %{school_name}",
            "ar" => "لـ %{school_name}",
            "tr" => "%{school_name} için",
            "pl" => "Dla %{school_name}",
            "fr" => "Pour %{school_name}",
            "uk" => "Для %{school_name}"
          },
          "Download PDF" => %{
            "de" => "PDF downloaden",
            "en" => "Download PDF",
            "ru" => "Скачать PDF",
            "ar" => "تحميل PDF",
            "tr" => "PDF İndir",
            "pl" => "Pobierz PDF",
            "fr" => "Télécharger PDF",
            "uk" => "Завантажити PDF"
          },
          "Sender" => %{
            "de" => "Absender",
            "en" => "Sender",
            "ru" => "Отправитель",
            "ar" => "المرسل",
            "tr" => "Gönderen",
            "pl" => "Nadawca",
            "fr" => "Expéditeur",
            "uk" => "Відправник"
          },
          "First Name" => %{
            "de" => "Vorname",
            "en" => "First Name",
            "ru" => "Имя",
            "ar" => "الاسم الأول",
            "tr" => "Ad",
            "pl" => "Imię",
            "fr" => "Prénom",
            "uk" => "Ім'я"
          },
          "Last Name" => %{
            "de" => "Nachname",
            "en" => "Last Name",
            "ru" => "Фамилия",
            "ar" => "اسم العائلة",
            "tr" => "Soyad",
            "pl" => "Nazwisko",
            "fr" => "Nom de famille",
            "uk" => "Прізвище"
          },
          "School and Student Information" => %{
            "de" => "Schul- und Schülerdaten",
            "en" => "School and Student Information",
            "ru" => "Информация о школе и ученике",
            "ar" => "معلومات المدرسة والطالب",
            "tr" => "Okul ve Öğrenci Bilgileri",
            "pl" => "Informacje o szkole i uczniu",
            "fr" => "Informations sur l'école et l'élève",
            "uk" => "Інформація про школу та учня"
          },
          "Title (optional)" => %{
            "de" => "Titel (optional)",
            "en" => "Title (optional)",
            "ru" => "Титул (необязательно)",
            "ar" => "اللقب (اختياري)",
            "tr" => "Unvan (isteğe bağlı)",
            "pl" => "Tytuł (opcjonalnie)",
            "fr" => "Titre (optionnel)",
            "uk" => "Титул (необов'язково)"
          },
          "Street and House Number (optional)" => %{
            "de" => "Straße und Hausnummer (optional)",
            "en" => "Street and House Number (optional)",
            "ru" => "Улица и номер дома (необязательно)",
            "ar" => "الشارع ورقم المنزل (اختياري)",
            "tr" => "Sokak ve Kapı Numarası (isteğe bağlı)",
            "pl" => "Ulica i numer domu (opcjonalnie)",
            "fr" => "Rue et numéro de maison (optionnel)",
            "uk" => "Вулиця та номер будинку (необов'язково)"
          },
          "ZIP Code" => %{
            "de" => "PLZ",
            "en" => "ZIP Code",
            "ru" => "Почтовый индекс",
            "ar" => "الرمز البريدي",
            "tr" => "Posta Kodu",
            "pl" => "Kod pocztowy",
            "fr" => "Code postal",
            "uk" => "Поштовий індекс"
          },
          "City" => %{
            "de" => "Stadt",
            "en" => "City",
            "ru" => "Город",
            "ar" => "المدينة",
            "tr" => "Şehir",
            "pl" => "Miasto",
            "fr" => "Ville",
            "uk" => "Місто"
          },
          "Information about the school and student" => %{
            "de" => "Informationen über die Schule und den Schüler",
            "en" => "Information about the school and student",
            "ru" => "Информация о школе и ученике",
            "ar" => "معلومات حول المدرسة والطالب",
            "tr" => "Okul ve öğrenci hakkında bilgiler",
            "pl" => "Informacje o szkole i uczniu",
            "fr" => "Informations sur l'école et l'élève",
            "uk" => "Інформація про школу та учня"
          },
          "Mr." => %{
            "de" => "Herr",
            "en" => "Mr.",
            "ru" => "Г-н",
            "ar" => "السيد",
            "tr" => "Bay",
            "pl" => "Pan",
            "fr" => "M.",
            "uk" => "Пан"
          },
          "Ms." => %{
            "de" => "Frau",
            "en" => "Ms.",
            "ru" => "Г-жа",
            "ar" => "السيدة",
            "tr" => "Bayan",
            "pl" => "Pani",
            "fr" => "Mme",
            "uk" => "Пані"
          },
          "Student Name" => %{
            "de" => "Name des Schülers/der Schülerin",
            "en" => "Student Name",
            "ru" => "Имя ученика",
            "ar" => "اسم الطالب",
            "tr" => "Öğrenci Adı",
            "pl" => "Imię i nazwisko ucznia",
            "fr" => "Nom de l'élève",
            "uk" => "Ім'я учня"
          },
          "Class" => %{
            "de" => "Klasse",
            "en" => "Class",
            "ru" => "Класс",
            "ar" => "الصف",
            "tr" => "Sınıf",
            "pl" => "Klasa",
            "fr" => "Classe",
            "uk" => "Клас"
          },
          "My relationship to the student:" => %{
            "de" => "Meine Beziehung zum Schüler:",
            "en" => "My relationship to the student:",
            "ru" => "Мое отношение к ученику:",
            "ar" => "علاقتي بالطالب:",
            "tr" => "Öğrenci ile ilişkim:",
            "pl" => "Mój stosunek do ucznia:",
            "fr" => "Ma relation avec l'élève:",
            "uk" => "Мої стосунки з учнем:"
          },
          "my son" => %{
            "de" => "mein Sohn",
            "en" => "my son",
            "ru" => "мой сын",
            "ar" => "ابني",
            "tr" => "oğlum",
            "pl" => "mój syn",
            "fr" => "mon fils",
            "uk" => "мій син"
          },
          "my daughter" => %{
            "de" => "meine Tochter",
            "en" => "my daughter",
            "ru" => "моя дочь",
            "ar" => "ابنتي",
            "tr" => "kızım",
            "pl" => "moja córka",
            "fr" => "ma fille",
            "uk" => "моя дочка"
          },
          "neither son nor daughter, but I have custody" => %{
            "de" => "weder Sohn, noch Tochter, aber ich bin sorgeberechtigt",
            "en" => "neither son nor daughter, but I have custody",
            "ru" => "ни сын, ни дочь, но у меня есть опека",
            "ar" => "لا ابن ولا ابنة، لكن لدي حضانة",
            "tr" => "ne oğul ne kız, ama velayetim var",
            "pl" => "ani syn, ani córka, ale mam opiekę prawną",
            "fr" => "ni fils ni fille, mais j'ai la garde",
            "uk" => "ні син, ні дочка, але я маю опіку"
          },
          "Start Date" => %{
            "de" => "Startdatum",
            "en" => "Start Date",
            "ru" => "Дата начала",
            "ar" => "تاريخ البداية",
            "tr" => "Başlangıç Tarihi",
            "pl" => "Data rozpoczęcia",
            "fr" => "Date de début",
            "uk" => "Дата початку"
          },
          "End Date" => %{
            "de" => "Enddatum",
            "en" => "End Date",
            "ru" => "Дата окончания",
            "ar" => "تاريخ النهاية",
            "tr" => "Bitiş Tarihi",
            "pl" => "Data zakończenia",
            "fr" => "Date de fin",
            "uk" => "Дата закінчення"
          },
          "Preview Example" => %{
            "de" => "Beispiel Vorschau",
            "en" => "Preview Example",
            "ru" => "Пример предварительного просмотра",
            "ar" => "مثال للمعاينة",
            "tr" => "Önizleme Örneği",
            "pl" => "Przykład podglądu",
            "fr" => "Exemple d'aperçu",
            "uk" => "Приклад попереднього перегляду"
          },
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
                "Dieses Projekt ist Open Source und lebt von der Beteiligung der Community. Haben Sie Feedback oder Feature-Wünsche (andere Formulare oder Briefe)? Besuchen Sie uns auf GitHub und erstellen Sie ein Issue!",
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
            "de" => "GitHub Projekt besuchen",
            "en" => "Visit GitHub Project",
            "ru" => "Посетить проект на GitHub",
            "ar" => "زيارة مشروع GitHub",
            "tr" => "GitHub Projesini Ziyaret Et",
            "pl" => "Odwiedź projekt GitHub",
            "fr" => "Visiter le projet GitHub",
            "uk" => "Відвідати проект на GitHub"
          },
          "Detailed Reason" => %{
            "de" => "Begründung",
            "en" => "Detailed Reason",
            "ru" => "Подробная причина",
            "ar" => "السبب المفصل",
            "tr" => "Ayrıntılı Neden",
            "pl" => "Szczegółowy powód",
            "fr" => "Raison détaillée",
            "uk" => "Детальна причина"
          }
        }
      end

      # These must be implemented by the using module
      def get_default_form_data, do: raise("get_default_form_data/0 must be implemented")
      def get_date_fields, do: raise("get_date_fields/0 must be implemented")
      def get_required_fields, do: raise("get_required_fields/0 must be implemented")
      def get_page_title(_school_name), do: raise("get_page_title/1 must be implemented")
      def get_translations, do: raise("get_translations/0 must be implemented")

      defoverridable get_default_form_data: 0,
                     get_date_fields: 0,
                     get_required_fields: 0,
                     get_page_title: 1,
                     get_translations: 0
    end
  end
end
