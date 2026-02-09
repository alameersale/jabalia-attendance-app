# تطبيق الحضور والانصراف - بلدية جباليا النزلة

تطبيق Flutter للحضور والانصراف يعمل بدون إنترنت (Offline-First) مع مزامنة تلقائية.

## المميزات

- ✅ تسجيل حضور الموظفين
- ✅ تسجيل حضور مبكر (08:00)
- ✅ العمل بدون إنترنت
- ✅ مزامنة تلقائية عند توفر الاتصال
- ✅ البحث عن الموظفين
- ✅ إدارة الجلسات
- ✅ واجهة عربية

## المتطلبات

1. Flutter SDK (3.0+)
2. Android Studio أو VS Code
3. جهاز Android أو محاكي

## التثبيت

### 1. تثبيت Flutter

```bash
# تحميل Flutter من الموقع الرسمي
https://flutter.dev/docs/get-started/install

# التحقق من التثبيت
flutter doctor
```

### 2. إعداد المشروع

```bash
# الدخول لمجلد التطبيق
cd flutter_attendance_app

# تثبيت المكتبات
flutter pub get

# بناء التطبيق للأندرويد
flutter build apk --release
```

### 3. تعديل رابط API

افتح الملف `lib/config/api_config.dart` وعدّل الرابط:

```dart
static const String baseUrl = 'https://jabalia.ps/api';
```

## بناء التطبيق

### APK للتثبيت المباشر

```bash
flutter build apk --release
```

الملف الناتج: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle لمتجر Google Play

```bash
flutter build appbundle --release
```

## هيكل المشروع

```
lib/
├── main.dart                 # نقطة البداية
├── config/
│   └── api_config.dart       # إعدادات API
├── models/
│   ├── employee.dart         # نموذج الموظف
│   └── attendance_record.dart # نموذج سجل الحضور
├── services/
│   ├── api_service.dart      # خدمة API
│   └── database_service.dart # قاعدة البيانات المحلية
├── providers/
│   ├── auth_provider.dart    # إدارة المصادقة
│   ├── attendance_provider.dart # إدارة الحضور
│   └── sync_provider.dart    # إدارة المزامنة
├── screens/
│   ├── login_screen.dart     # شاشة تسجيل الدخول
│   └── home_screen.dart      # الشاشة الرئيسية
└── widgets/
    ├── employee_card.dart    # بطاقة الموظف
    ├── session_card.dart     # بطاقة الجلسة
    └── sync_indicator.dart   # مؤشر المزامنة
```

## كيف يعمل Offline

1. **تخزين الموظفين**: عند الاتصال، يتم تخزين قائمة الموظفين محلياً
2. **تسجيل الحضور**: يتم حفظ السجلات في SQLite
3. **المزامنة التلقائية**: عند توفر الاتصال، يتم إرسال السجلات للسيرفر
4. **مؤشر المزامنة**: يظهر عدد السجلات غير المتزامنة

## API Endpoints

| Endpoint | Method | الوصف |
|----------|--------|-------|
| `/attendance/login` | POST | تسجيل الدخول |
| `/attendance/logout` | POST | تسجيل الخروج |
| `/attendance/employees` | GET | قائمة الموظفين |
| `/attendance/session` | GET | الجلسة الحالية |
| `/attendance/session` | POST | إنشاء جلسة |
| `/attendance/session/close` | POST | إغلاق الجلسة |
| `/attendance/mark` | POST | تسجيل حضور |
| `/attendance/sync` | POST | مزامنة السجلات |
| `/attendance/cancel/{id}` | DELETE | إلغاء حضور |

## الدعم

للمساعدة أو الإبلاغ عن مشاكل، تواصل مع فريق التطوير.
