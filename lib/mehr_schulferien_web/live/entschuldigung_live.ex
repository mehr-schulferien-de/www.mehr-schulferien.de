defmodule MehrSchulferienWeb.EntschuldigungLive do
  use MehrSchulferienWeb.DocumentLiveBase, document_type: "entschuldigung"

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
      reason: "krankheit",
      start_date: Date.utc_today(),
      end_date: Date.utc_today(),
      teacher_salutation: "Herr",
      teacher_name: "",
      child_type: "mein_sohn"
    }
  end

  def get_date_fields, do: [:start_date, :end_date]

  def get_required_fields do
    [
      {:first_name, "Vorname"},
      {:last_name, "Nachname"},
      {:zip_code, "PLZ"},
      {:city, "Stadt"},
      {:name_of_student, "Name des Schülers/der Schülerin"},
      {:class_name, "Klasse"}
    ]
  end

  def get_page_title(school_name), do: "Entschuldigungsvordruck - #{school_name}"

  def get_translations do
    %{
      "Create Excuse Letter" => %{
        "de" => "Entschuldigungsvordruck erstellen",
        "en" => "Create Excuse Form Template",
        "ru" => "Создать шаблон справки об отсутствии",
        "ar" => "إنشاء نموذج رسالة عذر",
        "tr" => "Mazeret Formu Şablonu Oluştur",
        "pl" => "Utwórz szablon usprawiedliwienia",
        "fr" => "Créer un modèle de lettre d'excuse",
        "uk" => "Створити шаблон виправдального листа"
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
      "Simply download as PDF" => %{
        "de" => "Vordruck als PDF downloaden",
        "en" => "Download form template as PDF",
        "ru" => "Скачать шаблон формы как PDF",
        "ar" => "تحميل نموذج المستند كـ PDF",
        "tr" => "Form şablonunu PDF olarak indir",
        "pl" => "Pobierz szablon formularza jako PDF",
        "fr" => "Télécharger le modèle de formulaire en PDF",
        "uk" => "Завантажити шаблон форми як PDF"
      },
      "Download PDF" => %{
        "de" => "Vordruck als PDF downloaden",
        "en" => "Download Form Template as PDF",
        "ru" => "Скачать шаблон формы PDF",
        "ar" => "تحميل نموذج PDF",
        "tr" => "Form Şablonunu PDF İndir",
        "pl" => "Pobierz szablon PDF",
        "fr" => "Télécharger le modèle PDF",
        "uk" => "Завантажити шаблон PDF"
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
      "Your personal information for the excuse letter" => %{
        "de" => "Ihre persönlichen Daten für die Entschuldigung",
        "en" => "Your personal information for the excuse letter",
        "ru" => "Ваша личная информация для справки",
        "ar" => "معلوماتك الشخصية لرسالة العذر",
        "tr" => "Mazeret mektubu için kişisel bilgileriniz",
        "pl" => "Twoje dane osobowe do usprawiedliwienia",
        "fr" => "Vos informations personnelles pour la lettre d'excuse",
        "uk" => "Ваша особиста інформація для виправдального листа"
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
      "Excuse Details" => %{
        "de" => "Entschuldigungsdetails",
        "en" => "Excuse Details",
        "ru" => "Детали оправдания",
        "ar" => "تفاصيل العذر",
        "tr" => "Mazeret Detayları",
        "pl" => "Szczegóły usprawiedliwienia",
        "fr" => "Détails de l'excuse",
        "uk" => "Деталі виправдання"
      },
      "Reason and period of absence" => %{
        "de" => "Grund und Zeitraum der Abwesenheit",
        "en" => "Reason and period of absence",
        "ru" => "Причина и период отсутствия",
        "ar" => "سبب وفترة الغياب",
        "tr" => "Devamsızlık nedeni ve süresi",
        "pl" => "Powód i okres nieobecności",
        "fr" => "Motif et période d'absence",
        "uk" => "Причина та період відсутності"
      },
      "Reason for Excuse" => %{
        "de" => "Grund der Entschuldigung",
        "en" => "Reason for Excuse",
        "ru" => "Причина оправдания",
        "ar" => "سبب العذر",
        "tr" => "Mazeret Nedeni",
        "pl" => "Powód usprawiedliwienia",
        "fr" => "Motif de l'excuse",
        "uk" => "Причина виправдання"
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
      "Generate a free excuse letter according to %{standard}. You can print the PDF or sign it digitally and send it to the school by email." =>
        %{
          "de" =>
            "Erstellen Sie kostenlos einen Entschuldigungsvordruck nach %{standard}. Das PDF können Sie ausdrucken, ausfüllen, unterschreiben und selbst bei der Schule einreichen. Dies ist ein Service von mehr-schulferien.de.",
          "en" =>
            "Create a free excuse form template according to %{standard}. You can print the PDF, fill it out, sign it and submit it to the school. This is a service by mehr-schulferien.de.",
          "ru" =>
            "Сгенерируйте бесплатную справку об отсутствии согласно %{standard}. Вы можете распечатать PDF или подписать его цифровой подписью и отправить в школу по электронной почте.",
          "ar" =>
            "قم بإنشاء رسالة عذر مجانية وفقاً لـ %{standard}. يمكنك طباعة ملف PDF أو توقيعه رقمياً وإرساله إلى المدرسة عبر البريد الإلكتروني.",
          "tr" =>
            "%{standard}'a göre ücretsiz bir mazeret mektubu oluşturun. PDF'yi yazdırabilir veya dijital olarak imzalayıp okula e-posta ile gönderebilirsiniz.",
          "pl" =>
            "Wygeneruj bezpłatne usprawiedliwienie zgodnie z %{standard}. Możesz wydrukować PDF lub podpisać go cyfrowo i wysłać do szkoły e-mailem.",
          "fr" =>
            "Générez gratuitement une lettre d'excuse selon %{standard}. Vous pouvez imprimer le PDF ou le signer numériquement et l'envoyer à l'école par e-mail.",
          "uk" =>
            "Згенеруйте безкоштовний виправдальний лист відповідно до %{standard}. Ви можете роздрукувати PDF або підписати його цифровим підписом і надіслати до школи електронною поштою."
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
      "Illness" => %{
        "de" => "Krankheit",
        "en" => "Illness",
        "ru" => "Болезнь",
        "ar" => "مرض",
        "tr" => "Hastalık",
        "pl" => "Choroba",
        "fr" => "Maladie",
        "uk" => "Хвороба"
      },
      "Doctor Appointment" => %{
        "de" => "Arzttermin",
        "en" => "Doctor Appointment",
        "ru" => "Прием у врача",
        "ar" => "موعد طبي",
        "tr" => "Doktor Randevusu",
        "pl" => "Wizyta u lekarza",
        "fr" => "Rendez-vous médical",
        "uk" => "Прийом у лікаря"
      },
      "Family Matters" => %{
        "de" => "Familiäre Angelegenheiten",
        "en" => "Family Matters",
        "ru" => "Семейные дела",
        "ar" => "أمور عائلية",
        "tr" => "Aile İşleri",
        "pl" => "Sprawy rodzinne",
        "fr" => "Affaires familiales",
        "uk" => "Сімейні справи"
      },
      "Funeral" => %{
        "de" => "Beerdigung",
        "en" => "Funeral",
        "ru" => "Похороны",
        "ar" => "جنازة",
        "tr" => "Cenaze",
        "pl" => "Pogrzeb",
        "fr" => "Funérailles",
        "uk" => "Похорон"
      },
      "Religious Holiday" => %{
        "de" => "Religiöser Feiertag",
        "en" => "Religious Holiday",
        "ru" => "Религиозный праздник",
        "ar" => "عطلة دينية",
        "tr" => "Dini Tatil",
        "pl" => "Święto religijne",
        "fr" => "Fête religieuse",
        "uk" => "Релігійне свято"
      }
    }
  end

  # Get available reasons for the dropdown
  def reasons(locale \\ "de") do
    [
      {translate("Illness", locale), "krankheit"},
      {translate("Doctor Appointment", locale), "arzttermin"},
      {translate("Family Matters", locale), "familiaere_angelegenheiten"},
      {translate("Funeral", locale), "beerdigung"},
      {translate("Religious Holiday", locale), "religioser_feiertag"}
    ]
  end
end
