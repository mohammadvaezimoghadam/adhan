# راهنمای جامع و چک‌لیست انتشار پچ OTA (OTA Patch Cheat Sheet)

این مستند، راهنمای گام‌به‌گام و عملیاتی برای **کامپایل، تولید بسته‌های پچ (Patch)، و انتشار خودکار روی سرور آپدیتر قرآن تفکر** است.

---

## ۱. مشخصات و متغیرهای سرور آپدیتر

| پارامتر | مقدار | توضیحات |
| :--- | :--- | :--- |
| **آدرس سرور (Host)** | `http://5.22.203.61` | سرور اصلی مدیریت و توزیع پچ‌های OTA |
| **شناسه برنامه (App ID)** | `quran_tafakor` | شناسه اختصاصی پروژه قرآن تفکر |
| **کانال انتشار (Channel)** | `stable` | کانال پیش‌فرض و پایدار کاربران |
| **اندپوینت نسخه جدید (Shorebird-Grade)** | `POST /api/v1/ota/publish/` | دریافت بسته تجمیعی Multi-ABI و استعلام با `/api/v1/ota/check/` |
| **اندپوینت داشبورد و لگسی** | `POST /api/patches/upload` | اندپوینت پنل مدیریت سرور و استعلام با `GET /check` |

> [!NOTE]
> با هر بار ارسال و فعال‌سازی پچ جدید، نسخه قبلی روی سرور به صورت خودکار به وضعیت **Archived** تغییر وضعیت می‌دهد و نسخه جدید فعال می‌شود.

---

## ۲. روش اول: انتشار خودکار با یک دستور (پیشنهادی و فوق‌سریع)

یک اسکریپت اختصاصی پایتون در پوشه `tool/publish_patch.py` آماده شده است که تمام مراحل (بیلد APK، محاسبه هش‌ها، پکینگ پچ‌ها، و آپلود به سرور) را در یک خط انجام می‌دهد:

### حالت کامل (بیلد + پک + انتشار خودکار به سرور):
```bash
python tool/publish_patch.py --version 1.0.13 --notes "توضیحات و تغییرات نسخه جدید" --server http://5.22.203.61
```

### حالت سریع (اگر بیلد APK از قبل گرفته شده و فقط می‌خواهید پچ را آپلود کنید):
```bash
python tool/publish_patch.py --version 1.0.13 --notes "توضیحات و تغییرات نسخه جدید" --server http://5.22.203.61 --skip-build
```

**عملیاتی که این دستور انجام می‌دهد:**
1. در صورت نیاز `flutter build apk --split-per-abi` را اجرا می‌کند.
2. با دستور `flutter_patcher:pack` پچ معماری‌های مختلف (`arm64-v8a`, `armeabi-v7a`, `x86_64`) را می‌سازد.
3. فایل `manifest.json` و باندل یکپارچه را تولید می‌کند.
4. فایل پچ را به هر دو اندپوینت سرور (`/api/patches/upload` و `/api/v1/ota/publish/`) ارسال کرده و نسخه جدید را مستقیماً فعال می‌کند.

---

## ۳. روش دوم: مراحل گام‌به‌گام دستی (Manual Workflow)

اگر مایل هستید هر مرحله را جداگانه کنترل و تست کنید:

### گام ۱: تست صحت کدها
```bash
flutter analyze
```
> اطمینان حاصل کنید که خطایی (`error`) وجود نداشته باشد.

### گام ۲: بیلد ریلیز تفکیک‌شده معماری‌ها
```bash
flutter build apk --split-per-abi
```
> خروجی‌ها در مسیر `build/app/outputs/flutter-apk/` تولید می‌شوند:
> - `app-arm64-v8a-release.apk` (گوشی‌های واقعی ۶۴ بیتی - بیش از ۹۵٪ کاربران)
> - `app-armeabi-v7a-release.apk` (گوشی‌های قدیمی ۳۲ بیتی)
> - `app-x86_64-release.apk` (شبیه‌ساز و امولاتور)

### گام ۳: پک کردن باینری پچ با ابزار Patcher
شماره نسخه پچ جدید (مثلاً `1.0.13`) را جایگزین `<PATCH_VERSION>` کنید:

#### برای گوشی‌های واقعی (`arm64-v8a` با target code ۲۰۰۱):
```bash
dart run flutter_patcher:pack --apk build/app/outputs/flutter-apk/app-arm64-v8a-release.apk --version <PATCH_VERSION> --target-version-code 2001 --abi arm64-v8a --out patches_output/arm64-v8a
```
> خروجی: `patches_output/arm64-v8a/patch.zip` (~4.5 MB)

#### برای شبیه‌ساز و امولاتور (`x86_64` با target code ۱):
```bash
dart run flutter_patcher:pack --apk build/app/outputs/flutter-apk/app-x86_64-release.apk --version <PATCH_VERSION> --target-version-code 1 --abi x86_64 --out patches_output/x86_64
```
> خروجی: `patches_output/x86_64/patch.zip`

### گام ۴: ارسال و فعال‌سازی روی سرور آپدیتر

می‌توانید با اسکریپت ساده پایتون یا از طریق فرم داشبورد وب فایل را آپلود کنید:

#### مشخصات فیلدهای فرم آپلود در سرور:
- **فایل (file):** فایل `patches_output/arm64-v8a/patch.zip`
- **شناسه برنامه (app_id):** `quran_tafakor`
- **ورژن (version):** نسخه جدید (مثلاً `1.0.13`)
- **کد نسخه هدف (target_version_code):** `1`
- **معماری هدف (target_abi):** `multi`
- **فعال‌سازی فوری (activate):** `1`
- **اجباری بودن (is_force):** `0`
- **توضیحات (notes):** متن فارسی تغییرات

#### اسکریپت آپلود سریع پایتون:
```python
import requests

url = "http://5.22.203.61/api/patches/upload"
patch_file = r"patches_output\arm64-v8a\patch.zip"

data = {
    "app_id": "quran_tafakor",
    "version": "1.0.13",
    "target_version_code": "1",
    "target_abi": "multi",
    "is_force": "0",
    "activate": "1",
    "notes": "متن تغییرات پچ جدید",
    "filename": "patch.zip",
}

with open(patch_file, "rb") as f:
    session = requests.Session()
    session.trust_env = False  # جلوگیری از اختلال پراکسی
    resp = session.post(
        url,
        data=data,
        files={"file": ("patch.zip", f, "application/zip")},
        timeout=900,
    )
    print("نتیجه:", resp.status_code, resp.json())
```

---

## ۴. استعلام و راستی‌آزمایی پچ جدید روی سرور

پس از ارسال پچ، با این دستورات مطمئن شوید که سرور نسخه جدید را به درستی تحویل می‌دهد:

### ۱. استعلام کلاینت نسخه جدید (`POST /api/v1/ota/check/`):
```bash
python -c "import urllib.request, json; p={'app_id':'quran_tafakor','base_release':'1.0.0+1','abi':'arm64-v8a','current_patch_version':'1.0.12','channel':'stable'}; print(urllib.request.urlopen(urllib.request.Request('http://5.22.203.61/api/v1/ota/check/', data=json.dumps(p).encode(), headers={'Content-Type':'application/json'})).read().decode())"
```
> پاسخ مورد انتظار: `{"status": "PATCH_AVAILABLE", "patch": {"version": "1.0.13", ...}}`

### ۲. استعلام کلاینت نسخه قبلی (`GET /check`):
```bash
curl "http://5.22.203.61/check?app_id=quran_tafakor&current_patch=1.0.12"
```
> پاسخ مورد انتظار: `{"has_update": true, "update_type": "patch", "version": "1.0.13", ...}`

### ۳. بررسی لیست پچ‌های فعال در دیتابیس سرور:
```bash
curl "http://5.22.203.61/api/patches?app_id=quran_tafakor"
```

---

## ۵. نکات حیاتی و تجربیات مهم (Pro Tips & Gotchas)

1. **صعودی بودن شماره نسخه (Version Increments):**
   - سرور آپدیتر اجازه آپلود نسخه‌ای با شماره کمتر یا مساوی نسخه فعال قبلی را نمی‌دهد. همیشه شماره نسخه را افزایش دهید (`1.0.13` بعد از `1.0.12`).

2. **پهنای باند و تنظیم Timeout مناسب:**
   - سرعت ارسال آپلود (Upstream) از لوکال به سرور VPS معمولاً بین ۱۵ تا ۲۵ کیلوبایت بر ثانیه است. آپلود فایل ۴.۵ مگابایتی بین **۴ الی ۷ دقیقه** زمان می‌برد.
   - همیشه مقدار `timeout` را در کتابخانه‌های کلاینت یا اسکریپت پایتون روی **۶۰۰ الی ۹۰۰ ثانیه** قرار دهید تا خطای `ReadTimeout` رخ ندهد.

3. **تنظیم `session.trust_env = False` در پایتون:**
   - در سیستم‌عامل ویندوز، فعال بودن فیلترشکن یا تنظیمات پروکسی سیستمی ممکن است باعث قطع ارتباط سوکت با سرور شود. این تنظیم از بروز قطعی جلوگیری می‌کند.

4. **تغییرات کدهای نیتیو vs کدهای دارت:**
   - پچ‌های OTA موتور فلاتر (مانند Shorebird) شامل کدهای کامپایل‌شده دارت (`libapp.so` و دارایی‌ها) هستند.
   - اگر تغییری در فایل‌های نیتیو اندروید (`AndroidManifest.xml`، کتابخانه‌های جاوا/کاتلین در `build.gradle` یا پلاگین جدید با کد نیتیو) اعمال شود، قابل ارائه از طریق پچ OTA نیست و باید فایل APK جدید برای کاربر منتشر شود.

---

## ۶. اسناد مرتبط و نقشه راه بازطراحی آینده
- جهت مشاهده نقشه راه بازطراحی یکپارچه سرور و اتوماسیون کامل نسخه توسط بک‌اند، به سند [docs/ota_refactor_backend_and_cli.md](file:///d:/flutterProjects/quran/docs/ota_refactor_backend_and_cli.md) مراجعه کنید.
