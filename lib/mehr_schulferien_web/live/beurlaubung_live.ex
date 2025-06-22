defmodule MehrSchulferienWeb.BeurlaubungLive do
  use MehrSchulferienWeb, :live_view
  import Phoenix.HTML

  alias MehrSchulferien.Locations

  @impl true
  def mount(%{"school_slug" => school_slug} = params, session, socket) do
    # Get school information
    school = Locations.get_school_by_slug!(school_slug)
    city = Locations.get_location!(school.parent_location_id)
    county = Locations.get_location!(city.parent_location_id)
    federal_state = Locations.get_location!(county.parent_location_id)
    country = Locations.get_location!(federal_state.parent_location_id)

    # Initialize form with default values
    form_data = %{
      title: "",
      first_name: "",
      last_name: "",
      street: "",
      zip_code: "",
      city: "",
      name_of_student: "",
      class_name: "",
      start_date: Date.utc_today(),
      end_date: Date.utc_today(),
      teacher_salutation: "Herr",
      teacher_name: "",
      child_type: "mein_sohn",
      detailed_reason: ""
    }

    # Get locale from URL params, session, socket assigns, or default to "de"
    locale = params["locale"] || Map.get(session, "locale") || socket.assigns[:locale] || "de"

    # Set the Gettext locale for this process
    Gettext.put_locale(MehrSchulferienWeb.Gettext, locale)

    {:ok,
     assign(socket,
       school: school,
       city: city,
       county: county,
       federal_state: federal_state,
       country: country,
       form_data: form_data,
       page_title: "Beurlaubung - #{school.name}",
       locale: locale
     )}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form_data =
      socket.assigns.form_data
      |> Map.merge(atomize_keys(params))
      |> maybe_parse_dates()

    {:noreply, assign(socket, form_data: form_data)}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    form_data =
      socket.assigns.form_data
      |> Map.merge(atomize_keys(params))
      |> maybe_parse_dates()

    # Validate required fields
    case validate_form_data(form_data) do
      :ok ->
        # Generate PDF download URL with form data as query parameters
        pdf_url = build_pdf_url(socket.assigns.school.slug, form_data)

        # Keep form data instead of resetting it so user can reuse or modify
        {:noreply,
         socket
         |> assign(form_data: form_data)
         |> put_flash(
           :info,
           "PDF wurde erfolgreich erstellt. Sie können das Formular erneut ausfüllen oder die Daten anpassen."
         )
         |> push_event("open_pdf", %{url: pdf_url})}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(form_data: form_data)
         |> put_flash(:error, message)}
    end
  end

  # Handle locale changes from LanguageSwitcherComponent
  @impl true
  def handle_info({:change_locale, locale}, socket) do
    # Set Gettext locale
    Gettext.put_locale(MehrSchulferienWeb.Gettext, locale)

    # Update socket with new locale and force a full page reload to trigger LocalePlug
    {:noreply,
     socket
     |> assign(locale: locale)
     |> push_navigate(to: "/briefe/#{socket.assigns.school.slug}/beurlaubung?locale=#{locale}")}
  end

  # Helper functions
  defp atomize_keys(params) do
    params = Enum.into(params, %{}, fn {k, v} -> {String.to_atom(k), v} end)
    params
  end

  defp maybe_parse_dates(form_data) do
    form_data
    |> parse_date_field(:start_date)
    |> parse_date_field(:end_date)
  end

  defp parse_date_field(form_data, field) do
    case Map.get(form_data, field) do
      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> Map.put(form_data, field, date)
          {:error, _} -> form_data
        end

      _ ->
        form_data
    end
  end

  # Form validation
  defp validate_form_data(form_data) do
    required_fields = [
      {:first_name, "Vorname"},
      {:last_name, "Nachname"},
      {:zip_code, "PLZ"},
      {:city, "Stadt"},
      {:name_of_student, "Name des Schülers/der Schülerin"},
      {:class_name, "Klasse"},
      {:detailed_reason, "Begründung"}
    ]

    missing_fields =
      required_fields
      |> Enum.filter(fn {field, _label} ->
        value = Map.get(form_data, field)
        is_nil(value) or value == ""
      end)
      |> Enum.map(fn {_field, label} -> label end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Bitte füllen Sie alle Pflichtfelder aus: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  # Build PDF download URL with form data
  defp build_pdf_url(school_slug, form_data) do
    query_params =
      form_data
      |> Map.new(fn {key, value} ->
        {to_string(key), format_param_value(value)}
      end)
      |> URI.encode_query()

    "/briefe/#{school_slug}/beurlaubung/pdf?#{query_params}"
  end

  defp format_param_value(%Date{} = date), do: Date.to_iso8601(date)
  defp format_param_value(value) when is_binary(value), do: value
  defp format_param_value(value), do: to_string(value)

  # Translation helper functions
  defp translate(key, locale) do
    translations = %{
      "Create Leave of Absence Request" => %{
        "de" => "Beurlaubung beantragen",
        "en" => "Create Leave of Absence Request",
        "ru" => "Создать заявление об отпуске",
        "ar" => "إنشاء طلب إجازة",
        "tr" => "İzin Talebi Oluştur",
        "pl" => "Utwórz wniosek o zwolnienie",
        "fr" => "Créer une demande de congé",
        "uk" => "Створити заяву про відпустку"
      },
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
      "Request approval in advance" => %{
        "de" => "Vorab um Genehmigung bitten",
        "en" => "Request approval in advance",
        "ru" => "Запросить одобрение заранее",
        "ar" => "طلب الموافقة مقدماً",
        "tr" => "Önceden onay isteyin",
        "pl" => "Prośba o zgodę z wyprzedzeniem",
        "fr" => "Demander une approbation à l'avance",
        "uk" => "Запросити схвалення заздалегідь"
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
      "Your personal information for the leave request" => %{
        "de" => "Ihre persönlichen Daten für den Beurlaubungsantrag",
        "en" => "Your personal information for the leave request",
        "ru" => "Ваша личная информация для заявления об отпуске",
        "ar" => "معلوماتك الشخصية لطلب الإجازة",
        "tr" => "İzin talebi için kişisel bilgileriniz",
        "pl" => "Twoje dane osobowe do wniosku o zwolnienie",
        "fr" => "Vos informations personnelles pour la demande de congé",
        "uk" => "Ваша особиста інформація для заяви про відпустку"
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
      "Class Teacher Salutation" => %{
        "de" => "Anrede Klassenlehrer(in)",
        "en" => "Class Teacher Salutation",
        "ru" => "Обращение к классному руководителю",
        "ar" => "مخاطبة المعلم الأساسي",
        "tr" => "Sınıf Öğretmeni Hitap Şekli",
        "pl" => "Forma zwrotu do wychowawcy",
        "fr" => "Salutation du professeur principal",
        "uk" => "Звернення до класного керівника"
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
      "Class Teacher Name" => %{
        "de" => "Name Klassenlehrer(in)",
        "en" => "Class Teacher Name",
        "ru" => "Имя классного руководителя",
        "ar" => "اسم المعلم الأساسي",
        "tr" => "Sınıf Öğretmeni Adı",
        "pl" => "Nazwisko wychowawcy",
        "fr" => "Nom du professeur principal",
        "uk" => "Ім'я класного керівника"
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
      "Leave Request Details" => %{
        "de" => "Beurlaubungsdetails",
        "en" => "Leave Request Details",
        "ru" => "Детали заявления об отпуске",
        "ar" => "تفاصيل طلب الإجازة",
        "tr" => "İzin Talebi Detayları",
        "pl" => "Szczegóły wniosku o zwolnienie",
        "fr" => "Détails de la demande de congé",
        "uk" => "Деталі заяви про відпустку"
      },
      "Reason and period of leave" => %{
        "de" => "Grund und Zeitraum der Beurlaubung",
        "en" => "Reason and period of leave",
        "ru" => "Причина и период отпуска",
        "ar" => "سبب وفترة الإجازة",
        "tr" => "İzin nedeni ve süresi",
        "pl" => "Powód i okres zwolnienia",
        "fr" => "Motif et période de congé",
        "uk" => "Причина та період відпустки"
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
      "Detailed Reason" => %{
        "de" => "Begründung",
        "en" => "Detailed Reason",
        "ru" => "Подробная причина",
        "ar" => "السبب المفصل",
        "tr" => "Ayrıntılı Neden",
        "pl" => "Szczegółowy powód",
        "fr" => "Raison détaillée",
        "uk" => "Детальна причина"
      },
      "Please provide a detailed explanation for the leave request" => %{
        "de" => "Bitte geben Sie eine ausführliche Begründung für die Beurlaubung an",
        "en" => "Please provide a detailed explanation for the leave request",
        "ru" => "Пожалуйста, предоставьте подробное объяснение запроса на отпуск",
        "ar" => "يرجى تقديم شرح مفصل لطلب الإجازة",
        "tr" => "Lütfen izin talebi için ayrıntılı bir açıklama sağlayın",
        "pl" => "Proszę podać szczegółowe wyjaśnienie wniosku o zwolnienie",
        "fr" => "Veuillez fournir une explication détaillée pour la demande de congé",
        "uk" => "Будь ласка, надайте детальне пояснення щодо заяви про відпустку"
      },
      "Generate a free leave of absence request according to %{standard}. You can print the PDF or sign it digitally and send it to the school by email." =>
        %{
          "de" =>
            "Generieren Sie kostenlos einen Beurlaubungsantrag nach %{standard}. Das PDF können Sie ausdrucken oder digital unterschreiben und per E-Mail an die Schule senden.",
          "en" =>
            "Generate a free leave of absence request according to %{standard}. You can print the PDF or sign it digitally and send it to the school by email.",
          "ru" =>
            "Сгенерируйте бесплатное заявление об отпуске согласно %{standard}. Вы можете распечатать PDF или подписать его цифровой подписью и отправить в школу по электронной почте.",
          "ar" =>
            "قم بإنشاء طلب إجازة مجاني وفقاً لـ %{standard}. يمكنك طباعة ملف PDF أو توقيعه رقمياً وإرساله إلى المدرسة عبر البريد الإلكتروني.",
          "tr" =>
            "%{standard}'a göre ücretsiz bir izin talebi oluşturun. PDF'yi yazdırabilir veya dijital olarak imzalayıp okula e-posta ile gönderebilirsiniz.",
          "pl" =>
            "Wygeneruj bezpłatny wniosek o zwolnienie zgodnie z %{standard}. Możesz wydrukować PDF lub podpisać go cyfrowo i wysłać do szkoły e-mailem.",
          "fr" =>
            "Générez gratuitement une demande de congé selon %{standard}. Vous pouvez imprimer le PDF ou le signer numériquement et l'envoyer à l'école par e-mail.",
          "uk" =>
            "Згенеруйте безкоштовну заяву про відпустку відповідно до %{standard}. Ви можете роздрукувати PDF або підписати його цифровим підписом і надіслати до школи електронною поштою."
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
      "Religious Holidays (Optional)" => %{
        "de" => "Religiöse Feiertage (Optional)",
        "en" => "Religious Holidays (Optional)",
        "ru" => "Религиозные праздники (Необязательно)",
        "ar" => "الأعياد الدينية (اختياري)",
        "tr" => "Dini Bayramlar (İsteğe bağlı)",
        "pl" => "Święta religijne (Opcjonalnie)",
        "fr" => "Fêtes religieuses (Optionnel)",
        "uk" => "Релігійні свята (Необов'язково)"
      },
      "Select a religious holiday to auto-fill the reason" => %{
        "de" => "Wählen Sie einen religiösen Feiertag, um die Begründung automatisch auszufüllen",
        "en" => "Select a religious holiday to auto-fill the reason",
        "ru" => "Выберите религиозный праздник для автоматического заполнения причины",
        "ar" => "اختر عيدًا دينيًا لملء السبب تلقائيًا",
        "tr" => "Nedeni otomatik doldurmak için bir dini bayram seçin",
        "pl" => "Wybierz święto religijne, aby automatycznie wypełnić powód",
        "fr" => "Sélectionnez une fête religieuse pour remplir automatiquement la raison",
        "uk" => "Виберіть релігійне свято для автоматичного заповнення причини"
      },
      "-- Select holiday --" => %{
        "de" => "-- Feiertag auswählen --",
        "en" => "-- Select holiday --",
        "ru" => "-- Выберите праздник --",
        "ar" => "-- اختر العيد --",
        "tr" => "-- Bayram seçin --",
        "pl" => "-- Wybierz święto --",
        "fr" => "-- Sélectionner une fête --",
        "uk" => "-- Виберіть свято --"
      }
    }

    case translations[key] do
      %{} = translation_map ->
        translation_map[locale] || translation_map["en"] || key

      nil ->
        key
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

  # Get religious holidays for the dropdown
  def religious_holidays(locale \\ "de") do
    holidays = [
      # Muslim holidays
      %{
        name: %{
          "de" => "Eid al-Fitr (Zuckerfest)",
          "en" => "Eid al-Fitr",
          "ru" => "Ураза-байрам",
          "ar" => "عيد الفطر",
          "tr" => "Ramazan Bayramı",
          "pl" => "Eid al-Fitr",
          "fr" => "Aïd el-Fitr",
          "uk" => "Ід аль-Фітр"
        },
        reason: %{
          "de" =>
            "Beurlaubung für das islamische Fest des Fastenbrechens (Eid al-Fitr/Zuckerfest)",
          "en" => "Leave request for the Islamic festival of breaking the fast (Eid al-Fitr)",
          "ru" => "Отпуск для исламского праздника разговения (Ураза-байрам)",
          "ar" => "طلب إجازة لعيد الفطر المبارك",
          "tr" => "Ramazan Bayramı için izin talebi",
          "pl" => "Prośba o zwolnienie na islamskie święto przerwania postu (Eid al-Fitr)",
          "fr" => "Demande de congé pour la fête islamique de la rupture du jeûne (Aïd el-Fitr)",
          "uk" => "Заява про відпустку на ісламське свято розговіння (Ід аль-Фітр)"
        }
      },
      %{
        name: %{
          "de" => "Eid al-Adha (Opferfest)",
          "en" => "Eid al-Adha",
          "ru" => "Курбан-байрам",
          "ar" => "عيد الأضحى",
          "tr" => "Kurban Bayramı",
          "pl" => "Eid al-Adha",
          "fr" => "Aïd el-Adha",
          "uk" => "Ід аль-Адха"
        },
        reason: %{
          "de" => "Beurlaubung für das islamische Opferfest (Eid al-Adha)",
          "en" => "Leave request for the Islamic Festival of Sacrifice (Eid al-Adha)",
          "ru" => "Отпуск для исламского праздника жертвоприношения (Курбан-байрам)",
          "ar" => "طلب إجازة لعيد الأضحى المبارك",
          "tr" => "Kurban Bayramı için izin talebi",
          "pl" => "Prośba o zwolnienie na islamskie Święto Ofiarowania (Eid al-Adha)",
          "fr" => "Demande de congé pour la fête islamique du sacrifice (Aïd el-Adha)",
          "uk" => "Заява про відпустку на ісламське свято жертвоприношення (Ід аль-Адха)"
        }
      },
      # Jewish holidays
      %{
        name: %{
          "de" => "Rosch Haschana (Jüdisches Neujahrsfest)",
          "en" => "Rosh Hashanah",
          "ru" => "Рош ха-Шана",
          "ar" => "رأس السنة العبرية",
          "tr" => "Roş Aşana",
          "pl" => "Rosz ha-Szana",
          "fr" => "Roch Hachana",
          "uk" => "Рош га-Шана"
        },
        reason: %{
          "de" => "Beurlaubung für das jüdische Neujahrsfest (Rosch Haschana)",
          "en" => "Leave request for the Jewish New Year (Rosh Hashanah)",
          "ru" => "Отпуск для еврейского Нового года (Рош ха-Шана)",
          "ar" => "طلب إجازة لرأس السنة العبرية",
          "tr" => "Musevi Yeni Yılı (Roş Aşana) için izin talebi",
          "pl" => "Prośba o zwolnienie na żydowski Nowy Rok (Rosz ha-Szana)",
          "fr" => "Demande de congé pour le Nouvel An juif (Roch Hachana)",
          "uk" => "Заява про відпустку на єврейський Новий рік (Рош га-Шана)"
        }
      },
      %{
        name: %{
          "de" => "Jom Kippur (Versöhnungstag)",
          "en" => "Yom Kippur",
          "ru" => "Йом-Киппур",
          "ar" => "يوم كيبور",
          "tr" => "Yom Kipur",
          "pl" => "Jom Kipur",
          "fr" => "Yom Kippour",
          "uk" => "Йом-Кіпур"
        },
        reason: %{
          "de" => "Beurlaubung für den jüdischen Versöhnungstag (Jom Kippur)",
          "en" => "Leave request for the Jewish Day of Atonement (Yom Kippur)",
          "ru" => "Отпуск для еврейского Дня искупления (Йом-Киппур)",
          "ar" => "طلب إجازة ليوم الغفران اليهودي",
          "tr" => "Musevi Kefaret Günü (Yom Kipur) için izin talebi",
          "pl" => "Prośba o zwolnienie na żydowski Dzień Pojednania (Jom Kipur)",
          "fr" => "Demande de congé pour le jour juif du Grand Pardon (Yom Kippour)",
          "uk" => "Заява про відпустку на єврейський День спокути (Йом-Кіпур)"
        }
      },
      %{
        name: %{
          "de" => "Pessach (Passahfest)",
          "en" => "Passover",
          "ru" => "Песах",
          "ar" => "عيد الفصح اليهودي",
          "tr" => "Hamursuz Bayramı",
          "pl" => "Pesach",
          "fr" => "Pessah",
          "uk" => "Песах"
        },
        reason: %{
          "de" => "Beurlaubung für das jüdische Passahfest (Pessach)",
          "en" => "Leave request for the Jewish Passover (Pesach)",
          "ru" => "Отпуск для еврейской Пасхи (Песах)",
          "ar" => "طلب إجازة لعيد الفصح اليهودي",
          "tr" => "Musevi Fısıh Bayramı (Pesah) için izin talebi",
          "pl" => "Prośba o zwolnienie na żydowską Paschę (Pesach)",
          "fr" => "Demande de congé pour la Pâque juive (Pessah)",
          "uk" => "Заява про відпустку на єврейську Пасху (Песах)"
        }
      },
      # Russian Orthodox holidays
      %{
        name: %{
          "de" => "Orthodoxes Weihnachten",
          "en" => "Orthodox Christmas",
          "ru" => "Православное Рождество",
          "ar" => "عيد الميلاد الأرثوذكسي",
          "tr" => "Ortodoks Noeli",
          "pl" => "Prawosławne Boże Narodzenie",
          "fr" => "Noël orthodoxe",
          "uk" => "Православне Різдво"
        },
        reason: %{
          "de" => "Beurlaubung für das orthodoxe Weihnachtsfest am 7. Januar",
          "en" => "Leave request for Orthodox Christmas on January 7th",
          "ru" => "Отпуск для православного Рождества 7 января",
          "ar" => "طلب إجازة لعيد الميلاد الأرثوذكسي في 7 يناير",
          "tr" => "7 Ocak'taki Ortodoks Noeli için izin talebi",
          "pl" => "Prośba o zwolnienie na prawosławne Boże Narodzenie 7 stycznia",
          "fr" => "Demande de congé pour le Noël orthodoxe du 7 janvier",
          "uk" => "Заява про відпустку на православне Різдво 7 січня"
        }
      },
      %{
        name: %{
          "de" => "Orthodoxes Ostern",
          "en" => "Orthodox Easter",
          "ru" => "Православная Пасха",
          "ar" => "عيد الفصح الأرثوذكسي",
          "tr" => "Ortodoks Paskalyası",
          "pl" => "Prawosławna Wielkanoc",
          "fr" => "Pâques orthodoxes",
          "uk" => "Православна Пасха"
        },
        reason: %{
          "de" => "Beurlaubung für das orthodoxe Osterfest",
          "en" => "Leave request for Orthodox Easter",
          "ru" => "Отпуск для православной Пасхи",
          "ar" => "طلب إجازة لعيد الفصح الأرثوذكسي",
          "tr" => "Ortodoks Paskalyası için izin talebi",
          "pl" => "Prośba o zwolnienie na prawosławną Wielkanoc",
          "fr" => "Demande de congé pour les Pâques orthodoxes",
          "uk" => "Заява про відпустку на православну Пасху"
        }
      }
    ]

    Enum.map(holidays, fn holiday ->
      {
        holiday.name[locale] || holiday.name["de"],
        holiday.reason[locale] || holiday.reason["de"]
      }
    end)
  end
end
