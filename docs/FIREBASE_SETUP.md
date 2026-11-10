# إعداد Firebase لـ Circles V2

هذه الوثيقة تجهّز بيئة Firebase دون تضمين أسرار أو ملفات مشروع حقيقية في Git. قيم Firebase الموجودة في `lib/features/circles/data/circle_firebase_options.dart` هي إعدادات عميل، وليست بديلًا عن تسجيل تطبيقات المنصات في Firebase Console.

## Android

1. في Firebase Console افتح المشروع `dr-honey-b1dc5` أو المشروع المعتمد من فريق backend.
2. أضف تطبيق Android بالمعرّف `com.itqan.itqan`.
3. أضف بصمتي SHA-1 وSHA-256 لشهادة debug، ثم أضف بصمات شهادة release قبل النشر.
4. فعّل **Authentication → Sign-in method → Google**.
5. نزّل `google-services.json` وضعه محليًا في `android/app/google-services.json`. لا تغيّر اسمه ولا ترفعه إلى Git.
6. راجع أن Web/server client ID الموجود في إعداد Google يطابق `googleServerClientId` في `CircleFirebaseOptions`.
7. استخدم `firebase/android/google-services.json.example` كمرجع للحقول فقط؛ هذا الملف غير قابل للاستخدام حتى تُستبدل القيم من Firebase Console.

التطبيق الحالي يهيئ Firebase عبر `FirebaseOptions` يدويًا. لذلك لا ينبغي إضافة Google Services Gradle plugin أو تعديل Gradle إلا إذا اختيرت عملية التهيئة المولدة من FlutterFire كمعيار للمشروع.

## iOS

دعم iOS غير مكتمل في هذا الفرع. لإكماله:

1. أضف تطبيق iOS في Firebase بالـ bundle identifier المعتمد.
2. نزّل `GoogleService-Info.plist` وضعه في `ios/Runner/GoogleService-Info.plist`.
3. أضف الملف إلى target `Runner` في Xcode.
4. أضف إعداد iOS إلى `CircleFirebaseOptions.currentPlatform` أو أعد توليد الخيارات عبر FlutterFire.
5. أضف إعدادات APNs وPush Notifications وBackground Modes، ثم اختبر Google Sign-In وFCM على جهاز حقيقي.

لا تستخدم `firebase/ios/GoogleService-Info.plist.example` كملف تشغيل؛ إنه قالب توثيقي فقط.

## FCM

بعد تسجيل الدخول، يطلب التطبيق إذن الإشعارات، يقرأ FCM token، ثم يرسله إلى `POST /api/v1/me/push-installations`. عند تغيّر token يعيد التسجيل، وعند تسجيل الخروج يحاول حذفه. يجب أن يقبل backend تكرار التسجيل بأمان وأن يربط installation بالمستخدم والجهاز لا بالمستخدم فقط.

## متطلبات ما قبل إصدار APK

- توفير `google-services.json` محليًا أو اعتماد تهيئة Firebase اليدوية الموثقة.
- إضافة SHA-1/SHA-256 الصحيحة في Firebase.
- تشغيل `flutter analyze` ثم `flutter test` ثم `flutter build apk --release`.
- اختبار Google Sign-In وFCM على جهاز Android حقيقي؛ لا يكفي اختبار المحاكي لتأكيد استقبال الإشعارات في جميع الحالات.
- عدم وضع مفاتيح service account أو FCM server key داخل التطبيق أو Git.
