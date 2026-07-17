defmodule MehrSchulferienWeb.BeurlaubungLive do
  use MehrSchulferienWeb.DocumentLiveBase, document_type: "beurlaubung"

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
      start_date: Date.utc_today(),
      end_date: Date.utc_today(),
      teacher_salutation: "Herr",
      teacher_name: "",
      child_type: "mein_sohn",
      detailed_reason: ""
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
      {:class_name, "Klasse"},
      {:detailed_reason, "Begründung"}
    ]
  end

  def get_page_title(school_name) do
    alias MehrSchulferienWeb.Helpers.SeoTitleHelper
    truncated = SeoTitleHelper.truncate_school_name(school_name)
    "Beurlaubung - #{truncated}"
  end

  def get_translations do
    Map.merge(MehrSchulferienWeb.DocumentLiveBase.shared_translations(), %{
      "Create Leave of Absence Request" => %{
        "de" => "Beurlaubungsvordruck erstellen",
        "en" => "Create Leave of Absence Form Template",
        "ru" => "Создать заявление об отпуске",
        "ar" => "إنشاء طلب إجازة",
        "tr" => "İzin Talebi Oluştur",
        "pl" => "Utwórz wniosek o zwolnienie",
        "fr" => "Créer une demande de congé",
        "uk" => "Створити заяву про відпустку"
      },
      "Request approval in advance" => %{
        "de" => "Vordruck für Antrag vorab erstellen",
        "en" => "Create form template for advance approval request",
        "ru" => "Запросить одобрение заранее",
        "ar" => "طلب الموافقة مقدماً",
        "tr" => "Önceden onay isteyin",
        "pl" => "Prośba o zgodę z wyprzedzeniem",
        "fr" => "Demander une approbation à l'avance",
        "uk" => "Запросити схвалення заздалегідь"
      },
      "Download PDF" => %{
        "de" => "Vordruck als PDF downloaden",
        "en" => "Download Form Template as PDF",
        "ru" => "Скачать PDF",
        "ar" => "تحميل PDF",
        "tr" => "PDF İndir",
        "pl" => "Pobierz PDF",
        "fr" => "Télécharger PDF",
        "uk" => "Завантажити PDF"
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
            "Erstellen Sie kostenlos einen Beurlaubungsvordruck nach %{standard}. Das PDF können Sie ausdrucken, ausfüllen, unterschreiben und selbst bei der Schule einreichen. Dies ist ein Service von mehr-schulferien.de.",
          "en" =>
            "Create a free leave of absence form template according to %{standard}. You can print the PDF, fill it out, sign it and submit it to the school. This is a service by mehr-schulferien.de.",
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
    })
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
