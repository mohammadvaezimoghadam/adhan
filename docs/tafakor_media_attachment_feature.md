# سند فنی قابلیت پیوست رسانه (تصویر / ویدیو) در استودیو تفکر

> **وضعیت قابلیت:** فرانت‌اند (UI/UX و مدیریت وضعیت) تکمیل شد | اتصال به بکند و ربات‌ها در فاز بعدی تکمیل می‌شود.

---

## ۱. خلاصه تغییرات پیاده‌سازی شده در سمت فلاتر (Frontend)

تمامی کارهای مربوط به رابط کاربری، تعامل کاربر، انتخاب رسانه و پیش‌نمایش در دو فایل اصلی [tafakor_editor_screen.dart](file:///d:/flutterProjects/quran/lib/features/topic_studio/presentation/ui/tafakor_editor_screen.dart) و [topic_mini_drawer.dart](file:///d:/flutterProjects/quran/lib/features/topic_studio/presentation/widgets/topic_mini_drawer.dart) پیاده‌سازی شده‌اند:

### ۱.۱. دکمه پیوست چندرسانه‌ای
* **آیکون:** علامت بعلاوه (`CupertinoIcons.plus`) با اندازه و رنگ ملایم (`white38`/`black38`).
* **استایل:** کانتینر دایره‌ای ۳۸ در ۳۸ پیکسل با بردر نامحسوس و بدون وضعیت سلکت (کاملاً مینیمال).

### ۱.۲. پاپ‌آپ چندرسانه‌ای سبک ChatGPT ([topic_media_picker_sheet.dart](file:///d:/flutterProjects/quran/lib/features/topic_studio/presentation/widgets/topic_media_picker_sheet.dart))
* **موقعیت:** به صورت پاپ‌آپ کوچک و متمرکز (عرض ۱۴۸ پیکسل) دقیقاً در بالای دکمه بعلاوه باز می‌شود.
* **بدون سایه مزاحم:** تیرگی پس‌زمینه (`barrierColor`) شفاف شده تا محیط اطراف کدر نشود.
* **آیکون‌ها و تایپوگرافی:**
  * **تصویر:** آیکون توپُر `CupertinoIcons.photo_fill` هم‌وزن با ویدیو + عنوان «تصویر» با فونت مدیوم (`w500`).
  * **ویدیو:** آیکون توپُر `CupertinoIcons.videocam` + عنوان «ویدیو» با فونت مدیوم (`w500`).
  * بدون خط دیوایدر و بدون فلش‌های اضافی.

### ۱.۳. منطق محدودیت تک‌رسانه
* در هر یادداشت حداکثر **۱ رسانه (عکس یا ویدیو)** قابل الصاق است تا با دیتابیس فعلی تفکر همخوانی داشته باشد.
* در صورت وجود رسانه، لمس مجدد به کاربر هشدار می‌دهد که ابتدا فایل قبلی را حذف کند.
* پس از انتخاب، اسنک‌بار موفقیت نمایش داده نمی‌شود و فیدبک صرفاً به صورت لمسی (Haptic) و بصری فوری است.

### ۱.۴. پیش‌نمایش بندانگشتی ۱ در ۱ مینیمال
* کادر ۱ در ۱ (۷۲x۷۲ پیکسل) با گوشه‌های گرد ۱۲ پیکسل درست در ردیف بالایی تکست‌فیلد قرار دارد.
* دکمه ضربدر دایره‌ای (`xmark_circle_fill`) در گوشه بالا-چپ برای حذف سریع تعبیه شده است.
* تفکیک هوشمند تصویر و ویدیو: تصویر به کمک بایت‌ها رندر می‌شود و ویدیو با نشانگر فیلم/ویدیو نمایش می‌یابد تا کرش کُدک رخ ندهد.

### ۱.۵. مدیریت وضعیت (State Management)
* مدل [InDrawerEditorState](file:///d:/flutterProjects/quran/lib/features/topic_studio/application/controllers/in_drawer_editor_controller.dart):
  * فیلدهای `attachedImagePath`، `attachedImageBytes` و `attachedMediaType` ('image' | 'video').
  * گترهای `hasAttachedImage`، `isImage`، `isVideo`.
  * متدهای `setAttachedImage`، `setAttachedVideo` و `removeAttachedImage`.
* سرویس [IImagePickerService](file:///d:/flutterProjects/quran/lib/core/services/media/image_picker_service.dart):
  * مجهز به `pickImageFromGallery` و `pickVideoFromGallery`.

---

## ۲. اقدامات باقی‌مانده جهت تکمیل کامل قابلیت (Next Steps)

برای اتصال این بخش به سرور و ارسال واقعی فایل‌ها، مراحل زیر باید اجرا شوند:

### ۲.۱. ارسال با Multipart در دیالوگ ارسال ([send_to_topic_dialog.dart](file:///d:/flutterProjects/quran/lib/features/topic_studio/presentation/widgets/send_to_topic_dialog.dart))
در حال حاضر ارسال نوت فقط به صورت متنی (JSON) است:
```dart
final response = await dio.post(
  'notes/',
  data: {
    'topic': targetTopic.id,
    'content': content,
  },
);
```
**تغییر مورد نیاز:**
استفاده از `FormData` در Dio هنگام وجود رسانه:
```dart
final formData = FormData.fromMap({
  'topic': targetTopic.id,
  'content': content,
  'media_type': editorState.isVideo ? 'video' : 'image',
  if (editorState.attachedImagePath != null)
    'media_file': await MultipartFile.fromFile(editorState.attachedImagePath!),
});
```

### ۲.۲. تغییرات بکند تفکر (`D:\django\tafakormag_avapardaz`)
1. **سریالایزر (`apps/notes/serializers.py`):**
   * اضافه کردن `MultiPartParser` و اطمینان از ولیدیشن فیلدهای `media_file` و `media_type`.
2. **ربات تلگرام (`bot_runner/telegram_bot.py`):**
   * بررسی `post.media_file` و `post.media_type`:
     * اگر `media_type == 'image'`: استفاده از `bot.send_photo(...)` با کپشن متن یادداشت.
     * اگر `media_type == 'video'`: استفاده از `bot.send_video(...)` با کپشن متن یادداشت.
     * اگر متن خالی بود یا فقط متن بود: استفاده از همان `bot.send_message(...)`.
3. **ربات بله:**
   * پیاده‌سازی لاجیک مشابه برای پیام‌های تصویری و ویدیویی در وب‌سرویس بله.
