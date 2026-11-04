# مصادر فنية ورخص البيانات

## بيانات المصحف

- Tanzil تنزيل النص العثماني: https://tanzil.net/download/
- رخصة نص Tanzil: https://tanzil.net/docs/text_license
- بيانات السور والصفحات والأجزاء في Tanzil: https://tanzil.net/docs/Quran_Metadata

شروط Tanzil المنشورة تسمح بنسخ النص وتوزيعه حرفيًا في تطبيق، بشرط إبقاء النص دون تغيير، وإسناد المصدر ووضع رابط Tanzil وإرفاق إشعار الرخصة. أدرج المشروع ملف النص الأصلي الذي يتضمن كتلة حقوق النشر في آخره، كما أضاف `assets/data/TANZIL_LICENSE.txt`. تطبيع البحث نسخة مقارنة مؤقتة فقط؛ النص المعروض والملف المضمّن لا يُعدّلان.

## Quran Foundation Content API

- توثيق جلب الآيات حسب السورة: https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/verses-by-chapter-number/
- توثيق النص العثماني بوسوم التجويد: https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/quran-verses-uthmani-tajweed/
- شروط مطوري Quran Foundation: https://api-docs.quran.foundation/legal/developer-terms/
- توثيق قائمة الترجمات: https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/list-surah-translations/

توثيق Quran Foundation يشرح أن وسم `text_uthmani_tajweed` يحمل تعليمات التجويد داخل عناصر HTML من نوع `tajweed`. شروط المطور تمنع تعديل نص القرآن أو إعادة توزيع بيانات QF كحزمة منفصلة، وتحدّ تخزين المحتوى العادي إلى أسبوع واحد. لذلك يستخدم التطبيق النص المحلي الموزع وفق رخصة Tanzil لقراءة القرآن، ويجلب وسوم التجويد والتفسير والترجمات اختياريًا من API ويخزنها مدة لا تتجاوز 7 أيام.

## البحث الصوتي

- وثائق حزمة Flutter `speech_to_text`: https://pub.dev/packages/speech_to_text

توضح الوثائق أن الحزمة تستخدم خدمة التعرف الصوتي المتاحة على الجهاز، وأن اللغات المتاحة تختلف حسب إعدادات الجهاز. التعرف قد يستخدم خدمة شبكية. لذلك يختار التطبيق locale عربيًا مثبتًا، ويعرض النص المتعرف عليه للمراجعة قبل البحث، ولا يحفظ ملف الصوت.

موارد الترجمة في التطبيق تستخدم معرّف المورد `20` لترجمة Saheeh International الإنجليزية، و`31` لترجمة Muhammad Hamidullah الفرنسية. نص الترجمة يأتي من endpoint `/quran/translations/{resource_id}` بفلتر السورة أو الصفحة، ويخزن محليًا لمدة لا تتجاوز سبعة أيام.

- شاشة إطلاق Android 12+ تعتمد على الأيقونة المتجهية المحلية `android/app/src/main/res/drawable/ic_itqan_launcher.xml` وعلى `windowSplashScreenBackground` بلون الهوية؛ ليست هناك صورة أو خدمة خارجية مطلوبة.
