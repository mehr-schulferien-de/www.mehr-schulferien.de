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

        # Try to load saved data from cookies if available (passed via connect params)
        form_data =
          case get_connect_params(socket)["briefe_form_data"] do
            nil ->
              form_data

            "" ->
              form_data

            saved_data when is_binary(saved_data) ->
              case Jason.decode(saved_data) do
                {:ok, decoded} ->
                  # Merge saved data with defaults, preserving date fields and document-specific fields
                  form_data
                  |> Map.merge(atomize_cookie_keys(decoded))
                  # Enable checkbox if we loaded from cookie
                  |> Map.put(:save_in_cookie, true)

                {:error, _} ->
                  form_data
              end

            _ ->
              form_data
          end

        # Get page title
        page_title = get_page_title(school_data.school.name)

        # Get meta data
        meta_data = get_meta_data(school_data.school.name, @document_type)

        {:ok,
         socket
         |> assign(school_data)
         |> assign(
           form_data: form_data,
           page_title: page_title,
           locale: locale,
           document_type: @document_type
         )
         |> assign(meta_data)}
      end

      defp atomize_cookie_keys(map) do
        Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
      rescue
        _ -> %{}
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

        MehrSchulferienWeb.DocumentLiveBase.handle_save(
          socket,
          form_data,
          get_required_fields(),
          @document_type
        )
      end

      @impl true
      def handle_info({:change_locale, locale}, socket) do
        {:noreply, BriefeHelpers.handle_locale_change(socket, locale, @document_type)}
      end

      # Translation helpers
      defp translate(key, locale) do
        MehrSchulferienWeb.DocumentLiveBase.translate(key, locale, get_translations())
      end

      defp translate(key, locale, bindings) when is_map(bindings) do
        MehrSchulferienWeb.DocumentLiveBase.translate_with_bindings(
          key,
          locale,
          get_translations(),
          bindings
        )
      end

      # These must be implemented by the using module
      def get_default_form_data, do: raise("get_default_form_data/0 must be implemented")
      def get_date_fields, do: raise("get_date_fields/0 must be implemented")
      def get_required_fields, do: raise("get_required_fields/0 must be implemented")
      def get_page_title(_school_name), do: raise("get_page_title/1 must be implemented")
      def get_translations, do: raise("get_translations/0 must be implemented")

      def get_meta_data(school_name, document_type) do
        MehrSchulferienWeb.DocumentLiveBase.meta_data(school_name, document_type)
      end

      defoverridable get_default_form_data: 0,
                     get_date_fields: 0,
                     get_required_fields: 0,
                     get_page_title: 1,
                     get_translations: 0,
                     get_meta_data: 2
    end
  end

  @doc """
  Handles the save event for document LiveViews.
  Validates form data, generates PDF URL, and optionally saves to cookie.
  """
  def handle_save(socket, form_data, required_fields, document_type) do
    alias MehrSchulferienWeb.Live.Shared.BriefeHelpers

    case BriefeHelpers.validate_form_data(form_data, required_fields) do
      :ok ->
        pdf_url =
          BriefeHelpers.build_pdf_url(socket.assigns.school.slug, form_data, document_type)

        socket =
          socket
          |> Phoenix.Component.assign(form_data: form_data)
          |> Phoenix.LiveView.put_flash(:info, BriefeHelpers.pdf_success_message())
          |> Phoenix.LiveView.push_event("open_pdf", %{url: pdf_url})

        socket =
          if Map.get(form_data, :save_in_cookie, false) do
            fields_to_save = [
              :title,
              :first_name,
              :last_name,
              :street,
              :zip_code,
              :city,
              :teacher_salutation,
              :teacher_name,
              :name_of_student,
              :class_name,
              :child_type
            ]

            data_to_save =
              form_data
              |> Map.take(fields_to_save)
              |> Jason.encode!()

            Phoenix.LiveView.push_event(socket, "save_form_cookie", %{data: data_to_save})
          else
            socket
          end

        {:noreply, socket}

      {:error, message} ->
        {:noreply,
         socket
         |> Phoenix.Component.assign(form_data: form_data)
         |> Phoenix.LiveView.put_flash(:error, message)}
    end
  end

  @doc """
  Translates a key using the provided translations map and locale.
  Falls back to common translations, then to the key itself.
  """
  def translate(key, locale, translations) do
    case translations[key] do
      %{} = translation_map ->
        translation_map[locale] || translation_map["en"] || key

      nil ->
        case common_translations()[key] do
          %{} = translation_map ->
            translation_map[locale] || translation_map["en"] || key

          nil ->
            key
        end
    end
  end

  @doc """
  Translates a key with bindings interpolation.
  """
  def translate_with_bindings(key, locale, translations, bindings) when is_map(bindings) do
    translated = translate(key, locale, translations)

    result =
      Enum.reduce(bindings, translated, fn {k, v}, acc ->
        value_string =
          case v do
            {:safe, content} -> content
            _ -> to_string(v)
          end

        String.replace(acc, "%{#{k}}", value_string)
      end)

    if Enum.any?(bindings, fn {_, v} -> match?({:safe, _}, v) end) do
      Phoenix.HTML.raw(result)
    else
      result
    end
  end

  @doc """
  Returns meta data for a given document type and school name.
  """
  def meta_data(school_name, document_type) do
    case document_type do
      "entschuldigung" ->
        %{
          page_description:
            "Erstellen Sie eine Entschuldigung für #{school_name}. Einfaches Formular, professionelles PDF zum Download.",
          og_image: "/images/entschuldigung-dummy.png"
        }

      "beurlaubung" ->
        %{
          page_description:
            "Erstellen Sie einen Beurlaubungsantrag für #{school_name}. Einfaches Formular, professionelles PDF zum Download.",
          og_image: "/images/entschuldigung-dummy.png"
        }

      "sportbefreiung" ->
        %{
          page_description:
            "Erstellen Sie eine Sportbefreiung für #{school_name}. Einfaches Formular, professionelles PDF zum Download.",
          og_image: "/images/entschuldigung-dummy.png"
        }

      _ ->
        %{}
    end
  end

  @doc """
  Returns common translations shared by all document types.
  """
  def common_translations do
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
      "Save data in cookie" => %{
        "de" => "Daten in Cookie speichern",
        "en" => "Save data in cookie",
        "ru" => "Сохранить данные в куки",
        "ar" => "حفظ البيانات في ملف تعريف الارتباط",
        "tr" => "Verileri çerezde sakla",
        "pl" => "Zapisz dane w ciasteczku",
        "fr" => "Enregistrer les données dans un cookie",
        "uk" => "Зберегти дані в куки"
      },
      "Your address and student information will be saved locally for future use" => %{
        "de" =>
          "Ihre Adresse und Schülerdaten werden lokal für zukünftige Verwendung gespeichert",
        "en" => "Your address and student information will be saved locally for future use",
        "ru" =>
          "Ваш адрес и информация об ученике будут сохранены локально для будущего использования",
        "ar" => "سيتم حفظ عنوانك ومعلومات الطالب محليًا للاستخدام في المستقبل",
        "tr" =>
          "Adresiniz ve öğrenci bilgileriniz gelecekte kullanılmak üzere yerel olarak kaydedilecektir",
        "pl" => "Twój adres i dane ucznia zostaną zapisane lokalnie do przyszłego użytku",
        "fr" =>
          "Votre adresse et les informations de l'élève seront enregistrées localement pour une utilisation future",
        "uk" =>
          "Ваша адреса та інформація про учня будуть збережені локально для майбутнього використання"
      }
    }
  end
end
