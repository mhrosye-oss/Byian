# Circles V2 — API brief

## حالة الوثيقة

هذه الوثيقة تصف العقد الذي يستهلكه تطبيق Flutter في `feature/circles-v2`. ما هو موسوم **مستهلك في العميل** مستخرج من الكود الحالي. ما هو موسوم **يحتاج اعتماد backend** هو اقتراح صريح لا يجوز اعتباره عقدًا نهائيًا قبل تأكيد مساراته وأسماء حقوله من backend.

جذر API في التطبيق هو:

```text
{CIRCLES_API_BASE_URL}/api/v1
```

يمكن تغييره أثناء البناء عبر `--dart-define=CIRCLES_API_BASE_URL=https://...`.

## قواعد عامة

- الطلبات المحمية تحمل `Authorization: Bearer <session_token>` و`Accept: application/json`.
- `POST /auth/firebase` هو الاستثناء العام، ويستقبل Firebase ID token فقط.
- يقبل العميل غلاف استجابة اختياريًا من الشكل `{ "data": ... }`. إذا كانت `success: false` يعرض `message` ويقرأ `errors` للتحقق.
- التواريخ ISO-8601، والمعرّفات `uuid` نصية حيث ينص الجدول على ذلك.
- `401` برسالة `Invalid or expired token` يمسح جلسة التطبيق. `401` برسالة `Unauthenticated` يسجل خطأ تكامل ولا يُعامل كجلسة منتهية.

## المصادقة

### `POST /auth/firebase` — مستهلك في العميل

طلب:

```json
{ "id_token": "<firebase-id-token>" }
```

استجابة دنيا مطلوبة:

```json
{
  "token": "<64-character-session-token>",
  "user": {
    "id": 12,
    "name": "اسم المستخدم",
    "email": "user@example.com",
    "phone": null,
    "total_xp": 0,
    "total_coins": 0,
    "level": 1,
    "level_title": null
  }
}
```

`user` اختياري في العميل؛ عند غيابه يستدعي التطبيق `GET /auth/me`.

### `GET /auth/me` — مستهلك في العميل

يعيد المستخدم مباشرة أو داخل `data.user` أو `data` وفق الغلاف العام. الحقول المطلوبة: `id`, `name`, `email`.

### `POST /auth/logout` — مستهلك في العميل

لا يعتمد العميل على جسم استجابة معين. يجب أن يكون آمنًا عند انتهاء الجلسة.

## القراءة

| الطريقة | المسار | المصادقة | الشكل المتوقع |
|---|---|---:|---|
| GET | `/circles/types` | لا | قائمة أنواع؛ كل عنصر `id`, `key` أو `slug`, `name`, `description?` |
| GET | `/circles` | نعم | قائمة دوائر؛ `id`, `uuid`, `name` وحقول العضوية الاختيارية |
| GET | `/circles/{uuid}` | نعم | كائن دائرة |
| GET | `/circles/{uuid}/dashboard` | نعم | بيانات لوحة؛ يجب أن تتضمن ما يكفي للملخص |
| GET | `/circles/{uuid}/members` | نعم | قائمة أعضاء |
| GET | `/circles/{uuid}/activities` | نعم | قائمة نشاط |
| GET | `/circles/{uuid}/tasks` | نعم | قائمة مهام |
| GET | `/circles/{uuid}/whispers` | نعم | قائمة همسات |
| GET | `/whisper-templates` | لا | قائمة قوالب همسات |
| GET | `/me/tasks?status=pending,in_progress` | نعم | قائمة مهام عابرة للدوائر؛ لا يوجد fallback |

شكل مهمة أدنى:

```json
{
  "uuid": "task-uuid",
  "title": "مراجعة الورد",
  "description": null,
  "priority": "normal",
  "status": "pending",
  "progress_value": 0,
  "due_at": null,
  "circle_name": "دائرة الحفظ",
  "circle_uuid": "circle-uuid",
  "assigned_to_user_id": 12,
  "xp_reward": 10
}
```

## عمليات الكتابة المؤكدة من مسارات العميل

### `POST /circles` — مستهلك في العميل، يحتاج تثبيت الاستجابة

```json
{ "type_id": 1, "name": "دائرة الحفظ", "description": "وصف اختياري" }
```

يجب أن يعيد backend دائرة منشأة أو كائنًا داخل `data`، وأن يعيد `422` مع `errors` عند فشل التحقق.

### `POST /circles/{uuid}/leave` — مستهلك في العميل

لا يحتاج جسمًا. الأخطاء المتوقعة: `403` للصلاحية و`409` إذا كانت الحالة تمنع المغادرة.

### `POST /circle-tasks/{taskUuid}/complete` — مستهلك في العميل

لا يحتاج جسمًا. يجب أن يكون idempotent أو يعيد `409` موثقًا عند إكمال المهمة سابقًا.

### الدعوات — مستهلكة في العميل، تحتاج اعتماد backend

- `POST /circles/{uuid}/invitations`
- `POST /invitations/preview` بجسم `{ "code": "..." }` وبدون مصادقة
- `POST /invitations/redeem` بجسم `{ "code": "..." }`

يستخدم التطبيق حاليًا لتوليد دعوة:

```json
{ "suggested_role": "member", "max_uses": 5, "valid_hours": 168 }
```

يجب تثبيت أسماء الاستجابة وحقول انتهاء الدعوة قبل تحويل العرض الخام إلى واجهة مخصصة.

### `POST /me/push-installations` — يحتاج اعتماد backend

```json
{ "installation_id": "<fcm-token>", "platform": "android" }
```

يجب أن يكون التسجيل upsert بحسب المستخدم والمنصة/التثبيت، لا أن ينشئ صفًا جديدًا عند كل refresh للرمز.

### `DELETE /me/push-installations/{installationId}` — يحتاج اعتماد backend

يحذف تسجيل التثبيت الحالي فقط، ويجب أن يكون idempotent.

## عمليات الكتابة غير المكتملة في واجهة المنتج

الدوال التالية موجودة في عميل Flutter لكنها لا تُستدعى من واجهة مكتملة لأن payload النهائي غير موثق:

### `POST /circles/{uuid}/tasks` — يحتاج اعتماد backend

يجب اعتماد الحقول المطلوبة، مثل العنوان، المكلّف، الأولوية، تاريخ الاستحقاق، ومكافأة XP، قبل بناء نموذج إنشاء المهمة.

### `POST /circles/{uuid}/whispers` — يحتاج اعتماد backend

يجب تحديد ما إذا كان الطلب يستخدم `template_key` أو `message_text` أو كليهما، وكيفية تمثيل `is_anonymous` والمستلمين.

### إرسال إشعار جماعي — غير معروف

لا يوجد endpoint في العميل الحالي. يجب تزويد الفريق بالمسار، الصلاحيات، payload، وحدود الحجم/المعدل قبل تفعيل الزر.

## أخطاء موحدة مطلوبة

```json
{
  "success": false,
  "message": "رسالة قابلة للعرض أو رمز معروف",
  "errors": {
    "name": ["اسم الحقل مطلوب"]
  }
}
```

- `401`: جلسة غير مصادق عليها أو رمز منتهٍ، مع تمييز الرسالتين كما سبق.
- `403`: لا توجد صلاحية.
- `404`: الدائرة/المهمة/الدعوة غير موجودة.
- `409`: تعارض حالة (عضو سابق، مهمة مكتملة، دعوة منتهية...).
- `422`: فشل تحقق، ويجب أن تكون `errors` خريطة حقول.

## قائمة اعتماد backend

قبل تفعيل العمليات الثلاث المعلقة، يلزم رد موثق على هذا الملف يثبت: المسارات النهائية، payloads، أمثلة 200/201، حالات 401/403/404/409/422، أسماء الحقول، سياسة idempotency لتسجيل FCM، وسياسة صلاحيات المالك. لا ينبغي للتطبيق تخمين هذه التفاصيل من ردود الإنتاج.
