# بناء التطبيق أونلاين (بدون تثبيت Flutter)

## الطريقة 1: استخدام Codemagic (مجاني)

### الخطوات:

1. **إنشاء حساب GitHub** (إذا لم يكن لديك):
   https://github.com/signup

2. **رفع المشروع على GitHub**:
   - أنشئ Repository جديد
   - ارفع محتويات هذا المجلد

3. **إنشاء حساب Codemagic**:
   https://codemagic.io/signup
   (سجل بحساب GitHub)

4. **ربط المشروع**:
   - اختر "Add application"
   - اختر Repository من GitHub
   - اختر "Flutter App"

5. **بناء التطبيق**:
   - اضغط "Start new build"
   - اختر "Android" → "APK"
   - انتظر البناء (10-15 دقيقة)

6. **تحميل APK**:
   - بعد انتهاء البناء، حمّل الملف

---

## الطريقة 2: استخدام GitHub Actions

أضف هذا الملف في المشروع:
`.github/workflows/build.yml`

```yaml
name: Build APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - run: flutter pub get
      - run: flutter build apk --release
      
      - uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
```

ثم:
1. ارفع المشروع على GitHub
2. اذهب لـ Actions
3. شغّل الـ Workflow
4. حمّل APK من Artifacts

---

## الطريقة 3: استخدام Appetize.io للاختبار

إذا أردت اختبار التطبيق بدون بناء:
https://appetize.io

---

## ملاحظة مهمة

قبل البناء، تأكد من تعديل رابط API في:
`lib/config/api_config.dart`

```dart
static const String baseUrl = 'https://jabalia.ps/api';
```
