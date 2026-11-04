# إتقان — المصحف ومواقيت الصلاة

مشروع Flutter المرفق، بهوية Light Mode: زمردي `#0A5C36`، كريمي `#F9F6F0`، وRose Gold `#B76E79`. الخطوط: Tajawal للواجهة وNoto Naskh للنص القرآني، مع تخطيط Bento في الرئيسية.

## الخدمات الحالية

**المصحف يعمل دون اتصال.** أُدرج نص Tanzil العثماني وبيانات السور وصفحات مصحف المدينة في `assets/data/`. يتحقق `QuranService` من عدد السور والآيات والصفحات عند التهيئة، ويعرض الفهرس والقراءة والبحث من الأصل المحلي بدل انتظار API. ملف `assets/data/TANZIL_LICENSE.txt` يذكر المصدر والرخصة؛ يحظر تعديل النص الأصلي، لذلك التطبيع يستخدم نسخة مقارنة مؤقتة للبحث فقط.

**البحث النصي والصوتي.** البحث النصي محلي ويزيل التشكيل وتنوعات الألف قبل المطابقة، ويظلل المطابقة بلون Rose Gold. البحث الصوتي يستخدم `speech_to_text` مع locale عربي متوفر على الجهاز، ويعرض النص المستخرج لتراجعه أو تعدله قبل الضغط على بحث. لا يحفظ التطبيق ملفًا صوتيًا؛ قد تعتمد خدمة التعرف في نظام التشغيل على الاتصال بالشبكة.

**التجويد.** وضع التلوين يجلب `text_uthmani_tajweed` الموسوم من Quran Foundation API، ويستخدم أسماء قواعد الوسوم بدلاً من تخمين الحكم من شكل حرف منفرد. يطابق التطبيق النص الموسوم بالنص المحلي قبل تلوينه. عند غياب الشبكة يبقى نص المصحف كاملًا متاحًا دون تلوين API.

**الترجمات والتفسير.** يمكن لقارئ السورة والصفحات جلب الترجمة الإنجليزية Saheeh International (resource `20`) أو الفرنسية Muhammad Hamidullah (resource `31`) حسب الإعداد. يُعرض تفسير ابن كثير العربي (resource `14`) في Bottom Sheet. محتوى Quran Foundation غير المحلي مخزن في Hive لمدة أقصاها سبعة أيام، وفشل API لا يمنع قراءة النص القرآني المحلي.

**الصلاة والأذان.** `adhan` يحسب المواقيت من GPS باستخدام إعدادات الحساب الحالية، و`flutter_local_notifications` يجدول تذكيرًا قبل الصلاة بـ15 دقيقة وإشعار دخول الوقت بصوت الأذان المضمّن. طلب الموقع مرتبط باستخدام الميزة، ولا يتطلب إذن موقع الخلفية.

**التلاوة ومزامنة الكلمات.** يتصل التطبيق اختياريًا بخدمة backend عبر `QURAN_TIMINGS_API_URL` لجلب توقيت الكلمة وقاعدة التجويد. لا توجد مفاتيح سرية مضمّنة في التطبيق. عند عدم ضبط backend يظل تشغيل التلاوة متاحًا دون مؤشرات توقيت دقيقة للكلمات.

## الاعتماديات ذات الصلة

المتطلبات الفعلية للميزات الحالية موجودة في `pubspec.yaml`، ويثبت `pubspec.lock` النسخ المحلولة. أهمها:

```yaml
dio: ^5.4.0
hive_flutter: ^1.1.0
flutter_riverpod: ^2.4.9
adhan: ^2.0.0+1
geolocator: ^14.0.0
flutter_local_notifications: ^17.2.2
flutter_timezone: ^5.1.1
timezone: ^0.9.4
speech_to_text: ^7.5.0
just_audio: ^0.9.36
```

لا يحتاج نص المصحف أو البحث المحلي إلى مفتاح API. API للترجمات والتفسير والتجويد خدمة محتوى عامة، وendpoint التوقيتات المخصص يجب أن يبقى خلف backend عند استخدام بيانات تتطلب مصادقة.

## بنية الملفات

```text
assets/data/
  tanzil-quran-uthmani.txt       # نص محلي أصلي، لا يُعدّل
  tanzil-quran-metadata.xml      # أسماء السور ومواضع الصفحات والأجزاء
  TANZIL_LICENSE.txt
lib/core/theme/                  # الألوان والخطوط والثيم
lib/features/home/               # الرئيسية Bento
lib/features/prayer/services/    # GPS وحساب المواقيت وإشعارات الصلاة
lib/features/quran/models/       # نموذج الآية والسورة
lib/features/quran/services/     # المصحف المحلي، التطبيع، API والكاش
lib/features/quran/screens/      # البحث النصي والصوتي
lib/features/mushaf/             # الفهرس وقارئ السورة والصفحات والتفسير
lib/features/tajweed/            # ألوان وسوم التجويد والتحقق من مطابقة النص
lib/features/recitation/         # التشغيل ومزامنة التوقيتات
lib/features/settings/           # إعدادات اللغة والترجمة والثيم
```

## الأذونات والأصول

يستخدم Android أذونات الموقع والإشعارات والصوت، ويُظهر محرك التعرف الصوتي عبر package visibility على Android 11+. يحتوي `Info.plist` على رسائل أذونات الميكروفون والتعرف الصوتي والموقع لـiOS. صوت الأذان داخل `assets/audio/` وموارد النظام الخاصة به في مجلدات Android وiOS.

## التوقيتات من backend

```bash
flutter run --dart-define=QURAN_TIMINGS_API_URL=https://your-backend.example
flutter build apk --release --dart-define=QURAN_TIMINGS_API_URL=https://your-backend.example
```

المسار المتوقع: `GET /v1/verses/{surah}:{ayah}/word-timings?reciter=alafasy`. يعيد `words` بعناصر `position`, `start_ms`, `end_ms`, `tajweed_rule`. الأوقات ميلي ثانية من بداية تسجيل القارئ ذاته.

## التشغيل والاختبارات

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

لإنشاء APK تجريبي ARM64: `flutter build apk --release --target-platform android-arm64`.

## مراجع البيانات والـAPI

تفاصيل المصادر وشروط الاستخدام موثقة في [مراجع المصادر الفنية](docs/source-references.md)، وفي إشعار Tanzil المضمّن. وثائق Quran Foundation المستخدمة هي: [وسوم التجويد](https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/quran-verses-uthmani-tajweed/) و[الآيات حسب السورة](https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/verses-by-chapter-number/).


## إصلاح شاشة الإطلاق Android

من الإصدار `1.0.5+6` استُبدلت أيقونة Flutter الافتراضية بأيقونة إتقان، وأضيفت إعدادات SplashScreen لـAndroid 12+ بخلفية كريمية. يؤجل التطبيق تهيئة Hive والإضافات إلى ما بعد أول إطار مرسوم. في `1.0.6+7` أصبح إطار البدء يستخدم ثيمًا بسيطًا محليًا بدل الثيم الكامل الذي يستدعي Google Fonts. إذا بقيت شاشة Android معلقة، فذلك يحتاج تشخيصًا على الجهاز وسجل `adb logcat`؛ بناء APK وحده لا يثبت سلوك كل جهاز.


## ملاحظة بناء الإصدار 1.0.7+8

الحزمة الحالية للتطبيق الأصلي مبنية بصيغة ARM64 Debug لتجاوز مشكلة ظهور شاشة فارغة في بناء Release/AOT ضمن بيئة البناء الحالية. هذا البناء ليس مخصصًا للنشر على المتجر، ويُبنى بالأمر `flutter build apk --debug --target-platform android-arm64 --split-per-abi`.
