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

  def get_page_title(school_name) do
    alias MehrSchulferienWeb.Helpers.SeoTitleHelper
    truncated = SeoTitleHelper.truncate_school_name(school_name)
    "Entschuldigung - #{truncated}"
  end

  def get_translations do
    Map.merge(MehrSchulferienWeb.DocumentLiveBase.shared_translations(), %{
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
    })
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
