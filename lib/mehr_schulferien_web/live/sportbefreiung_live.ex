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

  def get_page_title(school_name) do
    alias MehrSchulferienWeb.Helpers.SeoTitleHelper
    truncated = SeoTitleHelper.truncate_school_name(school_name)
    "Sportbefreiung - #{truncated}"
  end

  def get_translations do
    Map.merge(MehrSchulferienWeb.DocumentLiveBase.shared_translations(), %{
      "Sports Exemption Request" => %{
        "de" => "Sportbefreiungsvordruck erstellen",
        "en" => "Create Sports Exemption Form Template",
        "ru" => "Заявление об освобождении от физкультуры",
        "ar" => "طلب إعفاء من الرياضة",
        "tr" => "Spor Muafiyeti Talebi",
        "pl" => "Wniosek o zwolnienie z WF",
        "fr" => "Demande de dispense de sport",
        "uk" => "Заява про звільнення від фізкультури"
      },
      "Request sports exemption" => %{
        "de" => "Sportbefreiungsvordruck erstellen",
        "en" => "Create sports exemption form template",
        "ru" => "Запросить освобождение от физкультуры",
        "ar" => "طلب إعفاء من الرياضة",
        "tr" => "Spor muafiyeti talep et",
        "pl" => "Złóż wniosek o zwolnienie z WF",
        "fr" => "Demander une dispense de sport",
        "uk" => "Запросити звільнення від фізкультури"
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
            "Erstellen Sie kostenlos einen Sportbefreiungsvordruck nach %{standard}. Das PDF können Sie ausdrucken, ausfüllen, unterschreiben und selbst bei der Schule einreichen. Dies ist ein Service von mehr-schulferien.de.",
          "en" =>
            "Create a free sports exemption form template according to %{standard}. You can print the PDF, fill it out, sign it and submit it to the school. This is a service by mehr-schulferien.de.",
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
    })
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
