defmodule MehrSchulferienWeb.SportbefreiungLive do
  use MehrSchulferienWeb.DocumentLiveBase, document_type: "sportbefreiung"

  def get_default_form_data do
    %{
      title: "",
      first_name: "",
      last_name: "",
      street: "",
      zip_code: "",
      city: "",
      name_of_student: "",
      class_name: "",
      duration_type: "single_lesson",
      single_date: Date.utc_today(),
      start_date: Date.utc_today(),
      end_date: Date.utc_today(),
      teacher_salutation: "Herr",
      teacher_name: "",
      child_type: "mein_sohn",
      detailed_reason: "",
      medical_certificate: false
    }
  end

  def get_date_fields, do: [:single_date, :start_date, :end_date]

  def get_required_fields do
    [
      {:first_name, "Vorname"},
      {:last_name, "Nachname"},
      {:zip_code, "PLZ"},
      {:city, "Stadt"},
      {:name_of_student, "Name des Schülers/der Schülerin"},
      {:class_name, "Klasse"},
      {:detailed_reason, "Begründung"}
    ]
  end

  def get_page_title(school_name), do: "Sportbefreiung - #{school_name}"

  def get_translations do
    %{
      "Sports Exemption Request" => %{
        "de" => "Sportbefreiung beantragen",
        "en" => "Sports Exemption Request",
        "ru" => "Заявление об освобождении от физкультуры",
        "ar" => "طلب إعفاء من الرياضة",
        "tr" => "Spor Muafiyeti Talebi",
        "pl" => "Wniosek o zwolnienie z WF",
        "fr" => "Demande de dispense de sport",
        "uk" => "Заява про звільнення від фізкультури"
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
      "Request sports exemption" => %{
        "de" => "Sportbefreiung beantragen",
        "en" => "Request sports exemption",
        "ru" => "Запросить освобождение от физкультуры",
        "ar" => "طلب إعفاء من الرياضة",
        "tr" => "Spor muafiyeti talep et",
        "pl" => "Złóż wniosek o zwolnienie z WF",
        "fr" => "Demander une dispense de sport",
        "uk" => "Запросити звільнення від фізкультури"
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
      "Your personal information for the sports exemption request" => %{
        "de" => "Ihre persönlichen Daten für die Sportbefreiung",
        "en" => "Your personal information for the sports exemption request",
        "ru" => "Ваша личная информация для заявления об освобождении от физкультуры",
        "ar" => "معلوماتك الشخصية لطلب الإعفاء من الرياضة",
        "tr" => "Spor muafiyeti talebi için kişisel bilgileriniz",
        "pl" => "Twoje dane osobowe do wniosku o zwolnienie z WF",
        "fr" => "Vos informations personnelles pour la demande de dispense de sport",
        "uk" => "Ваша особиста інформація для заяви про звільнення від фізкультури"
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
      "Sports Teacher Salutation" => %{
        "de" => "Anrede Sportlehrer(in)",
        "en" => "Sports Teacher Salutation",
        "ru" => "Обращение к учителю физкультуры",
        "ar" => "مخاطبة معلم الرياضة",
        "tr" => "Beden Eğitimi Öğretmeni Hitap Şekli",
        "pl" => "Forma zwrotu do nauczyciela WF",
        "fr" => "Salutation du professeur de sport",
        "uk" => "Звернення до вчителя фізкультури"
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
      "Sports Teacher Name" => %{
        "de" => "Name Sportlehrer(in)",
        "en" => "Sports Teacher Name",
        "ru" => "Имя учителя физкультуры",
        "ar" => "اسم معلم الرياضة",
        "tr" => "Beden Eğitimi Öğretmeni Adı",
        "pl" => "Nazwisko nauczyciela WF",
        "fr" => "Nom du professeur de sport",
        "uk" => "Ім'я вчителя фізкультури"
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
      "Sports Exemption Details" => %{
        "de" => "Details zur Sportbefreiung",
        "en" => "Sports Exemption Details",
        "ru" => "Детали освобождения от физкультуры",
        "ar" => "تفاصيل الإعفاء من الرياضة",
        "tr" => "Spor Muafiyeti Detayları",
        "pl" => "Szczegóły zwolnienia z WF",
        "fr" => "Détails de la dispense de sport",
        "uk" => "Деталі звільнення від фізкультури"
      },
      "Duration and reason for sports exemption" => %{
        "de" => "Dauer und Grund der Sportbefreiung",
        "en" => "Duration and reason for sports exemption",
        "ru" => "Продолжительность и причина освобождения от физкультуры",
        "ar" => "مدة وسبب الإعفاء من الرياضة",
        "tr" => "Spor muafiyeti süresi ve nedeni",
        "pl" => "Czas trwania i powód zwolnienia z WF",
        "fr" => "Durée et raison de la dispense de sport",
        "uk" => "Тривалість та причина звільнення від фізкультури"
      },
      "Duration Type:" => %{
        "de" => "Art der Befreiung:",
        "en" => "Duration Type:",
        "ru" => "Тип освобождения:",
        "ar" => "نوع المدة:",
        "tr" => "Muafiyet Türü:",
        "pl" => "Rodzaj zwolnienia:",
        "fr" => "Type de dispense:",
        "uk" => "Тип звільнення:"
      },
      "Single sports lesson" => %{
        "de" => "Einzelne Sportstunde",
        "en" => "Single sports lesson",
        "ru" => "Один урок физкультуры",
        "ar" => "حصة رياضية واحدة",
        "tr" => "Tek ders",
        "pl" => "Pojedyncza lekcja WF",
        "fr" => "Une seule séance de sport",
        "uk" => "Один урок фізкультури"
      },
      "Period of time" => %{
        "de" => "Zeitraum",
        "en" => "Period of time",
        "ru" => "Период времени",
        "ar" => "فترة زمنية",
        "tr" => "Belirli bir süre",
        "pl" => "Okres czasu",
        "fr" => "Période de temps",
        "uk" => "Період часу"
      },
      "Date" => %{
        "de" => "Datum",
        "en" => "Date",
        "ru" => "Дата",
        "ar" => "التاريخ",
        "tr" => "Tarih",
        "pl" => "Data",
        "fr" => "Date",
        "uk" => "Дата"
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
      "Medical Certificate" => %{
        "de" => "Ärztliches Attest",
        "en" => "Medical Certificate",
        "ru" => "Медицинская справка",
        "ar" => "شهادة طبية",
        "tr" => "Doktor Raporu",
        "pl" => "Zaświadczenie lekarskie",
        "fr" => "Certificat médical",
        "uk" => "Медична довідка"
      },
      "Medical certificate attached" => %{
        "de" => "Ärztliches Attest liegt bei",
        "en" => "Medical certificate attached",
        "ru" => "Медицинская справка прилагается",
        "ar" => "الشهادة الطبية مرفقة",
        "tr" => "Doktor raporu ektedir",
        "pl" => "Zaświadczenie lekarskie w załączeniu",
        "fr" => "Certificat médical joint",
        "uk" => "Медична довідка додається"
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
      "Please provide a detailed explanation for the sports exemption request" => %{
        "de" => "Bitte geben Sie eine ausführliche Begründung für die Sportbefreiung an",
        "en" => "Please provide a detailed explanation for the sports exemption request",
        "ru" =>
          "Пожалуйста, предоставьте подробное объяснение запроса на освобождение от физкультуры",
        "ar" => "يرجى تقديم شرح مفصل لطلب الإعفاء من الرياضة",
        "tr" => "Lütfen spor muafiyeti talebi için ayrıntılı bir açıklama sağlayın",
        "pl" => "Proszę podać szczegółowe wyjaśnienie wniosku o zwolnienie z WF",
        "fr" => "Veuillez fournir une explication détaillée pour la demande de dispense de sport",
        "uk" => "Будь ласка, надайте детальне пояснення щодо заяви про звільнення від фізкультури"
      },
      "Generate a free sports exemption request according to %{standard}. You can print the PDF or sign it digitally and send it to the school by email." =>
        %{
          "de" =>
            "Generieren Sie kostenlos einen Antrag auf Sportbefreiung nach %{standard}. Das PDF können Sie ausdrucken oder digital unterschreiben und per E-Mail an die Schule senden.",
          "en" =>
            "Generate a free sports exemption request according to %{standard}. You can print the PDF or sign it digitally and send it to the school by email.",
          "ru" =>
            "Сгенерируйте бесплатное заявление об освобождении от физкультуры согласно %{standard}. Вы можете распечатать PDF или подписать его цифровой подписью и отправить в школу по электронной почте.",
          "ar" =>
            "قم بإنشاء طلب إعفاء من الرياضة مجاني وفقاً لـ %{standard}. يمكنك طباعة ملف PDF أو توقيعه رقمياً وإرساله إلى المدرسة عبر البريد الإلكتروني.",
          "tr" =>
            "%{standard}'a göre ücretsiz bir spor muafiyeti talebi oluşturun. PDF'yi yazdırabilir veya dijital olarak imzalayıp okula e-posta ile gönderebilirsiniz.",
          "pl" =>
            "Wygeneruj bezpłatny wniosek o zwolnienie z WF zgodnie z %{standard}. Możesz wydrukować PDF lub podpisać go cyfrowo i wysłać do szkoły e-mailem.",
          "fr" =>
            "Générez gratuitement une demande de dispense de sport selon %{standard}. Vous pouvez imprimer le PDF ou le signer numériquement et l'envoyer à l'école par e-mail.",
          "uk" =>
            "Згенеруйте безкоштовну заяву про звільнення від фізкультури відповідно до %{standard}. Ви можете роздрукувати PDF або підписати його цифровим підписом і надіслати до школи електронною поштою."
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
      "Common Medical Reasons (Optional)" => %{
        "de" => "Häufige medizinische Gründe (Optional)",
        "en" => "Common Medical Reasons (Optional)",
        "ru" => "Распространенные медицинские причины (Необязательно)",
        "ar" => "الأسباب الطبية الشائعة (اختياري)",
        "tr" => "Yaygın Tıbbi Nedenler (İsteğe bağlı)",
        "pl" => "Częste przyczyny medyczne (Opcjonalnie)",
        "fr" => "Raisons médicales courantes (Optionnel)",
        "uk" => "Поширені медичні причини (Необов'язково)"
      },
      "Select a common reason to auto-fill" => %{
        "de" => "Wählen Sie einen häufigen Grund zum automatischen Ausfüllen",
        "en" => "Select a common reason to auto-fill",
        "ru" => "Выберите распространенную причину для автоматического заполнения",
        "ar" => "اختر سببًا شائعًا للملء التلقائي",
        "tr" => "Otomatik doldurmak için yaygın bir neden seçin",
        "pl" => "Wybierz częstą przyczynę do automatycznego wypełnienia",
        "fr" => "Sélectionnez une raison courante pour remplir automatiquement",
        "uk" => "Виберіть поширену причину для автоматичного заповнення"
      },
      "-- Select reason --" => %{
        "de" => "-- Grund auswählen --",
        "en" => "-- Select reason --",
        "ru" => "-- Выберите причину --",
        "ar" => "-- اختر السبب --",
        "tr" => "-- Neden seçin --",
        "pl" => "-- Wybierz powód --",
        "fr" => "-- Sélectionner une raison --",
        "uk" => "-- Виберіть причину --"
      }
    }
  end

  # Get common medical reasons for the dropdown
  def medical_reasons(locale \\ "de") do
    reasons = [
      # Orthopedic reasons
      %{
        name: %{
          "de" => "Verletzung (z.B. Verstauchung, Zerrung)",
          "en" => "Injury (e.g. sprain, strain)",
          "ru" => "Травма (например, растяжение, ушиб)",
          "ar" => "إصابة (مثل التواء، إجهاد)",
          "tr" => "Yaralanma (örn. burkulma, zorlanma)",
          "pl" => "Uraz (np. skręcenie, naciągnięcie)",
          "fr" => "Blessure (ex. entorse, élongation)",
          "uk" => "Травма (наприклад, розтягнення, забій)"
        },
        reason: %{
          "de" =>
            "Aufgrund einer Verletzung kann mein Kind vorübergehend nicht am Sportunterricht teilnehmen. Ein ärztliches Attest liegt bei.",
          "en" =>
            "Due to an injury, my child is temporarily unable to participate in sports classes. A medical certificate is attached.",
          "ru" =>
            "Из-за травмы мой ребенок временно не может участвовать в уроках физкультуры. Медицинская справка прилагается.",
          "ar" =>
            "بسبب إصابة، لا يستطيع طفلي المشاركة مؤقتًا في حصص الرياضة. الشهادة الطبية مرفقة.",
          "tr" =>
            "Bir yaralanma nedeniyle çocuğum geçici olarak beden eğitimi derslerine katılamıyor. Doktor raporu ektedir.",
          "pl" =>
            "Ze względu na uraz moje dziecko tymczasowo nie może uczestniczyć w lekcjach WF. Zaświadczenie lekarskie w załączeniu.",
          "fr" =>
            "En raison d'une blessure, mon enfant ne peut temporairement pas participer aux cours de sport. Un certificat médical est joint.",
          "uk" =>
            "Через травму моя дитина тимчасово не може брати участь в уроках фізкультури. Медична довідка додається."
        }
      },
      %{
        name: %{
          "de" => "Nach Operation/Krankenhausaufenthalt",
          "en" => "After surgery/hospital stay",
          "ru" => "После операции/госпитализации",
          "ar" => "بعد الجراحة/الإقامة في المستشفى",
          "tr" => "Ameliyat/hastane tedavisi sonrası",
          "pl" => "Po operacji/pobycie w szpitalu",
          "fr" => "Après une opération/hospitalisation",
          "uk" => "Після операції/перебування в лікарні"
        },
        reason: %{
          "de" =>
            "Nach einer Operation/einem Krankenhausaufenthalt muss sich mein Kind noch schonen und kann daher nicht am Sportunterricht teilnehmen.",
          "en" =>
            "After surgery/hospital stay, my child still needs to rest and therefore cannot participate in sports classes.",
          "ru" =>
            "После операции/госпитализации мой ребенок должен еще отдохнуть и поэтому не может участвовать в уроках физкультуры.",
          "ar" =>
            "بعد الجراحة/الإقامة في المستشفى، لا يزال طفلي بحاجة إلى الراحة ولذلك لا يمكنه المشاركة في حصص الرياضة.",
          "tr" =>
            "Ameliyat/hastane tedavisi sonrası çocuğumun dinlenmesi gerekiyor ve bu nedenle beden eğitimi derslerine katılamıyor.",
          "pl" =>
            "Po operacji/pobycie w szpitalu moje dziecko musi jeszcze odpoczywać i dlatego nie może uczestniczyć w lekcjach WF.",
          "fr" =>
            "Après une opération/hospitalisation, mon enfant doit encore se reposer et ne peut donc pas participer aux cours de sport.",
          "uk" =>
            "Після операції/перебування в лікарні моя дитина ще повинна відпочивати і тому не може брати участь в уроках фізкультури."
        }
      },
      %{
        name: %{
          "de" => "Asthma/Atemwegserkrankung",
          "en" => "Asthma/respiratory disease",
          "ru" => "Астма/заболевание дыхательных путей",
          "ar" => "الربو/أمراض الجهاز التنفسي",
          "tr" => "Astım/solunum yolu hastalığı",
          "pl" => "Astma/choroba układu oddechowego",
          "fr" => "Asthme/maladie respiratoire",
          "uk" => "Астма/захворювання дихальних шляхів"
        },
        reason: %{
          "de" =>
            "Aufgrund einer akuten Atemwegserkrankung/Asthma kann mein Kind derzeit nicht am Sportunterricht teilnehmen.",
          "en" =>
            "Due to an acute respiratory disease/asthma, my child is currently unable to participate in sports classes.",
          "ru" =>
            "Из-за острого заболевания дыхательных путей/астмы мой ребенок в настоящее время не может участвовать в уроках физкультуры.",
          "ar" => "بسبب مرض تنفسي حاد/الربو، لا يستطيع طفلي حاليًا المشاركة في حصص الرياضة.",
          "tr" =>
            "Akut solunum yolu hastalığı/astım nedeniyle çocuğum şu anda beden eğitimi derslerine katılamıyor.",
          "pl" =>
            "Ze względu na ostrą chorobę układu oddechowego/astmę moje dziecko obecnie nie może uczestniczyć w lekcjach WF.",
          "fr" =>
            "En raison d'une maladie respiratoire aiguë/asthme, mon enfant ne peut actuellement pas participer aux cours de sport.",
          "uk" =>
            "Через гостре захворювання дихальних шляхів/астму моя дитина наразі не може брати участь в уроках фізкультури."
        }
      },
      %{
        name: %{
          "de" => "Kreislaufbeschwerden",
          "en" => "Circulatory problems",
          "ru" => "Проблемы с кровообращением",
          "ar" => "مشاكل في الدورة الدموية",
          "tr" => "Dolaşım problemleri",
          "pl" => "Problemy z krążeniem",
          "fr" => "Problèmes circulatoires",
          "uk" => "Проблеми з кровообігом"
        },
        reason: %{
          "de" =>
            "Aufgrund von Kreislaufbeschwerden ist meinem Kind die Teilnahme am Sportunterricht ärztlich untersagt.",
          "en" =>
            "Due to circulatory problems, my child is medically prohibited from participating in sports classes.",
          "ru" =>
            "Из-за проблем с кровообращением моему ребенку врачом запрещено участвовать в уроках физкультуры.",
          "ar" => "بسبب مشاكل في الدورة الدموية، يُمنع طفلي طبيًا من المشاركة في حصص الرياضة.",
          "tr" =>
            "Dolaşım problemleri nedeniyle çocuğumun beden eğitimi derslerine katılması tıbben yasaklanmıştır.",
          "pl" =>
            "Ze względu na problemy z krążeniem mojemu dziecku lekarsko zabroniono uczestnictwa w lekcjach WF.",
          "fr" =>
            "En raison de problèmes circulatoires, mon enfant est médicalement interdit de participer aux cours de sport.",
          "uk" =>
            "Через проблеми з кровообігом моїй дитині лікарем заборонено брати участь в уроках фізкультури."
        }
      },
      %{
        name: %{
          "de" => "Allergische Reaktion",
          "en" => "Allergic reaction",
          "ru" => "Аллергическая реакция",
          "ar" => "رد فعل تحسسي",
          "tr" => "Alerjik reaksiyon",
          "pl" => "Reakcja alergiczna",
          "fr" => "Réaction allergique",
          "uk" => "Алергічна реакція"
        },
        reason: %{
          "de" =>
            "Aufgrund einer allergischen Reaktion kann mein Kind vorübergehend nicht am Sportunterricht teilnehmen.",
          "en" =>
            "Due to an allergic reaction, my child is temporarily unable to participate in sports classes.",
          "ru" =>
            "Из-за аллергической реакции мой ребенок временно не может участвовать в уроках физкультуры.",
          "ar" => "بسبب رد فعل تحسسي، لا يستطيع طفلي المشاركة مؤقتًا في حصص الرياضة.",
          "tr" =>
            "Alerjik reaksiyon nedeniyle çocuğum geçici olarak beden eğitimi derslerine katılamıyor.",
          "pl" =>
            "Ze względu na reakcję alergiczną moje dziecko tymczasowo nie może uczestniczyć w lekcjach WF.",
          "fr" =>
            "En raison d'une réaction allergique, mon enfant ne peut temporairement pas participer aux cours de sport.",
          "uk" =>
            "Через алергічну реакцію моя дитина тимчасово не може брати участь в уроках фізкультури."
        }
      }
    ]

    Enum.map(reasons, fn reason ->
      {
        reason.name[locale] || reason.name["de"],
        reason.reason[locale] || reason.reason["de"]
      }
    end)
  end
end
