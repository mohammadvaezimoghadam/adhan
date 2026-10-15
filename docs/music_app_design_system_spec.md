# سند جامع سیستم طراحی و هویت بصری پلتفرم استریم موسیقی (Music Streaming Design System Spec)

این سند مرجع فنی و بصری کامل جهت توسعه پلتفرم استریم موسیقی جدید بر پایه سیستم طراحی یکپارچه **Quran Tafakor (Apple-Grade / Sacred Serenity)** است. تمام ابعاد، انحناها، رفتارها، تایپوگرافی، ساختار ویجت‌ها و میکرواینترکشن‌ها کاملاً حفظ شده و فقط توکن‌های رنگی و تمپلیت معنایی جهت کاربری موسیقی دگرگون می‌شوند.

---

## ۱. اصول و فلسفه طراحی (Design Principles)

1. **طراحی سطح بالا و برگرفته از استانداردهای اپل (Apple-grade Experience)**:
   - پرهیز از شلوغی، حاشیه‌ها و لبه‌های خشن.
   - استفاده از خطوط مویی بسیار ظریف (`0.8px` الی `1.0px`) برای جداسازی کارت‌ها و پنل‌ها به جای سایه‌های اغراق‌آمیز.
   - بهره‌گیری از شیشه‌ مات (Frosted Glass Blur) با `BackdropFilter` و مقادیر شفافیت (Alpha) کنترل‌شده.
2. **سیستم گرید فاصله‌گذاری ۸ پیکسلی (8-Point Grid)**:
   - تمام فاصله‌ها، ارتفاع‌ها و پدینگ‌ها بر پایه‌ی ضرایب عدد ۲، ۴ و ۸ هستند.
3. **بازخورد لمسی فراگیر (Omnipresent Haptics)**:
   - هر کلیک، تغییر تب، لایک و لمس دکمه پخش باید با بازخورد لمسی همراه باشد (`HapticFeedback.selectionClick()` یا `mediumImpact()`).
4. **حرکت و انیمیشن‌های روان (Micro-Interactions)**:
   - مدت زمان ترنزیشن‌ها معمولاً بین `150ms` تا `250ms` و با منحنی‌های طبیعی (`Curves.easeInOut` یا `Curves.easeOutCubic`).

---

## ۲. توکن‌های ابعادی و انحناها (Dimensions & Radius System)

برگرفته از `AppDimens` در اپلیکیشن مبدا:

```dart
class MusicDimens {
  // فاصله‌های کلی صفحه
  static const double marginPage = 20.0;
  static const double gutterGrid = 16.0;
  static const double safeAreaBottom = 34.0;

  // گرید فاصله‌گذاری عمودی و افقی (Spacing Units)
  static const double spaceXxSm = 2.0;
  static const double spaceXs   = 4.0;
  static const double spaceSm   = 8.0;
  static const double spaceSmMd = 12.0;
  static const double spaceMd   = 16.0;
  static const double spaceLg   = 24.0;
  static const double spaceXl   = 32.0;
  static const double space2Xl  = 40.0;

  // گوشه‌های گرد (BorderRadius)
  static const double radiusXs      = 6.0;   // بج‌های کوچک و تگ‌ها
  static const double radiusSm      = 10.0;  // کاورهای کوچک لیست ترک‌ها
  static const double radiusDefault = 14.0;  // فیلد‌های ورودی و دکمه‌های اصلی
  static const double radiusMd      = 16.0;  // کارت‌های آلبوم و کارت‌های اصلی
  static const double radiusLg      = 20.0;  // دیالوگ‌ها و پنجره‌ها
  static const double radiusXl      = 24.0;  // باتم‌شیت‌ها
  static const double radiusPill    = 999.0; // چیپ‌ها، دکمه‌های شناور و مینی پلیر
}
```

---

## ۳. تایپوگرافی (Typography Hierarchy)

فونت اصلی در سراسر پروژه **IRANSans** (یا **Vazirmatn**) با اعداد فارسی است.

| المان | اندازه (pt) | وزن (Weight) | ارتفاع سطر (Height) | کاربرد در اپ موسیقی |
| :--- | :--- | :--- | :--- | :--- |
| **Hero Title** | 28 - 32 | ExtraBold / Bold | 1.3 | عنوان صفحه اصلی / صفحه آرتیست |
| **Section Title** | 18 - 20 | Bold | 1.35 | تیتر بخش‌ها (مثلاً «آهنگ‌های پیشنهادی»، «پلی‌لیست‌ها») |
| **Track Title** | 14 - 15 | Bold / SemiBold | 1.3 | نام قطعه موسیقی در لیست‌ها |
| **Artist / Subtitle** | 12 - 12.5 | Regular | 1.25 | نام خواننده یا آلبوم (با رنگ خاکستری متغیر) |
| **Metadata & Badges** | 10 - 11 | Medium | 1.2 | مدت‌زمان آهنگ، کیفیت (320kbps/FLAC)، تاریخ انتشار |
| **Player Timecode** | 12 | SemiBold | 1.0 | تایمر زمان رفته و باقی‌مانده پلیر |
| **Lyric Line (Active)** | 18 - 20 | ExtraBold | 1.6 | سطر در حال پخش در حالت متن همگام (Synced Lyrics) |
| **Lyric Line (Normal)**| 15 - 16 | Medium | 1.6 | سطرهای پیشین و پسین متن موسیقی |

> **قاعده مهم**: کلیه ارقام مدت زمان، رتبه آهنگ، تعداد پلی و تاریخ باید با اکستنشن ارقام فارسی قالب‌بندی شوند (`۰۳:۴۵` به جای `03:45`).

---

## ۴. زبان آیکون‌ها (Cupertino Iconography)

از پکیج رسمی **`CupertinoIcons`** برای حفظ ظاهر اپل و تمیز بودن خطوط استفاده می‌شود:

- **پخش و کنترل**:
  - پخش: `CupertinoIcons.play_fill`
  - مکث: `CupertinoIcons.pause_fill`
  - ترک بعدی / قبلی: `CupertinoIcons.forward_end_fill` / `CupertinoIcons.backward_end_fill`
  - پخش تصادفی: `CupertinoIcons.shuffle`
  - تکرار: `CupertinoIcons.repeat` / `CupertinoIcons.repeat_1`
- **تعامل و اکشن‌ها**:
  - علاقه‌مندی: `CupertinoIcons.heart` (غیرفعال) / `CupertinoIcons.heart_fill` (فعال با رنگ اکسنت)
  - دانلود: `CupertinoIcons.arrow_down_circle` / `CupertinoIcons.arrow_down_circle_fill`
  - منوی بیشتر: `CupertinoIcons.ellipsis`
  - بستن دیالوگ/شیت: `CupertinoIcons.xmark_circle_fill`
  - افزودن به پلی‌لیست: `CupertinoIcons.text_badge_plus`
- **نویگیشن بار**:
  - خانه: `CupertinoIcons.house` / `CupertinoIcons.house_fill`
  - مرور و کاوش: `CupertinoIcons.compass` / `CupertinoIcons.compass_fill`
  - جستجو: `CupertinoIcons.search`
  - کتابخانه من: `CupertinoIcons.music_albums` / `CupertinoIcons.music_albums_fill`
  - پروفایل: `CupertinoIcons.person` / `CupertinoIcons.person_fill`

---

## ۵. سیستم رنگ‌ها و تم‌ها (Color Tokens - تنها بخش متغیر)

در اپ جدید، صرفاً رنگ پایه (Brand / Accent Color) تغییر می‌کند و ساختار متریال ۳ و اکستنشن‌های تم ثابت می‌مانند. به عنوان مثال، اگر برای موزیک از رنگ **بنفش نئونی (Cyber Violet)** یا **سبز رادیواکتیو موزیک (Electric Mint)** استفاده شود:

### مقایسه تم دارک و لایت:

```dart
class MusicColors {
  // رنگ‌های برند (قابل سفارشی‌سازی برای استریم موسیقی)
  static const Color primaryNeon        = Color(0xFF7C4DFF); // بنفش نئونی یا اسپاتیفای 0xFF1DB954
  static const Color primaryNeonLight   = Color(0xFFB388FF);
  static const Color primaryContainer   = Color(0xFF281C48);

  // پس‌زمینه‌های تاریک عمیق اپل (Dark Theme)
  static const Color darkScaffoldBg     = Color(0xFF000000); // مشکی خالص OLED
  static const Color darkSurfaceCard    = Color(0xFF1C1C1E); // پنل خاکستری تیره اپل
  static const Color darkCardBorder     = Color(0xFF2C2C2E); // خط مویی مرز کارت‌ها
  static const Color darkTextPrimary    = Color(0xFFFFFFFF);
  static const Color darkTextSecondary  = Color(0xFF8E8E93);
  static const Color darkCapsuleBg      = Color(0xFA171A21); // کپسول مینی پلیر

  // پس‌زمینه‌های روشن شفاف (Light Theme)
  static const Color lightScaffoldBg    = Color(0xFFF8F9FA);
  static const Color lightSurfaceCard   = Color(0xFFFFFFFF);
  static const Color lightCardBorder    = Color(0xFFEDE9E3);
  static const Color lightTextPrimary   = Color(0xFF1C1B1B);
  static const Color lightTextSecondary = Color(0xFF8A8A8E);
}
```

---

## ۶. مشخصات دقیق کامپوننت‌های رابط کاربری (UI Components Specification)

### ۶.۱. فیلدهای ورودی (Text Fields & Search Bar)
- **شکل**: کپسولی با انحنای `BorderRadius.circular(14)`.
- **رنگ پس‌زمینه**: `colors.cardBackground` (سفید در روز، `0xFF1C1C1E` در شب).
- **حاشیه‌ها (Borders)**:
  - حالت پیش‌فرض: `BorderSide(color: colors.cardBorder, width: 1.0)`.
  - حالت فوکوس: `BorderSide(color: colorScheme.primary, width: 1.5)`.
- **پدینگ داخلی**: `symmetric(horizontal: 16, vertical: 14)`.
- **پیشوند و پسوند**: آیکون جستجو `CupertinoIcons.search` در راست (در RTL) و دکمه ضربدر حذف متن در چپ.

### ۶.۲. تب‌بار سگمنتد کپسولی (Segmented Tab Bar)
برگرفته از `AppSegmentedTabBar`:
- **شکل کل تب**: ترک محاط با انحنای `14px` و حاشیه نازک `0.8px`.
- **ارتفاع کل**: `42.0px` با پدینگ داخلی `3.5px`.
- **پیل انتخاب‌شده (Active Pill)**:
  - انحنای داخلی: `11px`.
  - رنگ پس‌زمینه: رنگ Primary با شفافیت `0.15` تا `0.25` در دارک و `0.10` در لایت.
  - کادر دور پیل: رنگ Primary با شفافیت `0.30`.
- **انیمیشن**: تغییر سریع و بدون لگ با `HapticFeedback.selectionClick()`.

### ۶.۳. ناوبری پایینی (Bottom Navigation Bar)
برگرفته از `AppBottomNavBar`:
- **ارتفاع**: `60.0px + MediaQuery.paddingOf(context).bottom`.
- **افکت مه‌آلود (Frosted Glass)**:
  - ویجت `BackdropFilter` با `sigmaX: 20, sigmaY: 20`.
  - رنگ پس‌زمینه `cardBackground.withValues(alpha: isDark ? 0.88 : 0.94)`.
- **حاشیه بالایی**: خط مرزی بسیار باریک `Border(top: BorderSide(color: cardBorder, width: 0.8))`.
- **تغییر آیکون هنگام انتخاب**: سوییچ خودکار از آیکون خطی (مثلاً `house`) به نسخه توپر (`house_fill`) و پررنگ شدن لیبل متنی.

### ۶.۴. مودال‌ها، باتم‌شیت‌ها و دیالوگ‌ها (Modals & Sheets)
برگرفته از `AppModalHeader` و دیالوگ‌های پروژه:
- **انحنای بالایی شیت‌ها**: `24px`.
- **انحنای دیالوگ‌ها**: `20px` به همراه بردر دور `Border.all(color: cardBorder, width: 1.0)`.
- **هدر استاندارد (`AppModalHeader`)**:
  - دستگیره درگ (Drag Handle) در بالا با ابعاد `عرض 38، ارتفاع 4.5` و انحنای `3px`.
  - عنوان کاملاً بالانس و **وسط‌چین دقیق** با فونت سایز `16px Bold`.
  - دکمه بستن در سمت چپ (در زبان فارسی) به صورت `CupertinoIcons.xmark_circle_fill` با سایز `26px`.
  - خط جداکننده زیر هدر: اختیاری، ضخامت `0.8px`.

### ۶.۵. کارت‌ها و آیتم‌های لیست آهنگ‌ها (Track Tile & Cards)
- **کاور تصویر آهنگ (Thumbnail)**:
  - اندازه متداول در لیست: `48x48` یا `52x52` پیکسل.
  - انحنا: `10px` الی `12px` با کش شبکه و آیکون فال‌بک موقت.
- **ردیف آیتم آهنگ (`TrackTile`)**:
  - پدینگ: `symmetric(horizontal: 16, vertical: 8)`.
  - هاور و تاچ: `InkWell` با ردیوس `12px`، هنگام لمس پس‌زمینه با شفافیت `0.04` پر می‌شود.
  - اطلاعات: نام آهنگ (`fontSize: 14, FontWeight.bold`)، در خط بعد نام خواننده و مدت زمان (`fontSize: 12, Colors.white54`).
  - انتهای ردیف: دکمه منوی ۳ نقطه `CupertinoIcons.ellipsis` و آیکون انیمیشنی اکولایزر یا ویو در صورت فعال بودن آهنگ.

---

## ۷. سیستم پلیر اختصاصی موسیقی (Audio Player System)

### ۷.۱. مینی‌پلیر کپسولی شناور (Floating Capsule Mini Player)
برگرفته از `MiniAudioPlayerBar` پروژه تفکر:
- **موقعیت**: شناور با فاصله `8px` بالای نویگیشن بار.
- **ابعاد**: ارتفاع `44px`، انحنای کامل `BorderRadius.circular(22)`.
- **پس‌زمینه**: کپسول با رنگ `0xFA171A21` و خط بیرونی Primary با شفافیت `0.28`.
- **سایه**: `BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 6))`.
- **اجزای داخلی کپسول**:
  1. دکمه پلی/پاز مینیاتوری در ابتدای کپسول (قطر ۳۲ با پس‌زمینه Primary).
  2. نام آهنگ و خواننده به صورت متحرک یا متن فشرده در وسط کپسول.
  3. نوار پیشرفت مویی (Hairline Progress Bar) به ضخامت `2px` در پایین کپسول که میزان پیمایش آهنگ را نشان می‌دهد.
  4. کلیک روی کپسول: باز شدن نرم صفحه کامل پلیر (Full Player Modal).

### ۷.۲. پلیر تمام‌صفحه (Full-Screen Player Bottom Sheet)
- **کاور آلبوم بزرگ**: ابعاد مربعی متناسب با صفحه (حداکثر `320x320`) با گوشه‌های گرد `20px` و سایه غنی `BoxShadow(blurRadius: 32, spreadRadius: 2)`.
- **نوار اسلایدر زمان (Seek Bar)**:
  - خط باریک با رنگ پس‌زمینه شفاف، نوار پیشرفت با رنگ اکسنت نئونی.
  - تایم‌کدهای شروع و پایان در دو طرف اسلایدر با فونت اعداد فارسی.
- **دکمه‌های کنترل اصلی (Controls Row)**:
  - دکمه‌های قبلی/بعدی با سایز آیکون `28px`.
  - دکمه شافل و ریپیت با فیدبک روشن/خاموش شدن به رنگ اکسنت.
  - **دکمه اصلی Play/Pause**: دایره کامل با قطر `64px`، رنگ پس‌زمینه اکسنت تم و آیکون سفید یا مشکی کنتراست‌بالا.

---

## ۸. جدول تطبیق‌پذیری مفاهیم (Quran App ➔ Music App Mapping)

برای این که توسعه‌دهندگان بتوانند ساختار معماری، کنترلرها و کامپوننت‌های این مخزن را مستقیماً کپی و بازاستفاده کنند:

| کامپوننت / انتیتی در قرآن تفکر | معادل در پلتفرم استریم موسیقی | فایل الگوی مرجع |
| :--- | :--- | :--- |
| **`Surah`** | **`Album` / `Playlist`** | `lib/features/surah_list/` |
| **`Ayah`** | **`Track` / `Song`** | `lib/features/quran_reader/domain/entities/ayah.dart` |
| **`Reciter` (قاری)** | **`Artist` / `Singer`** | `lib/common/widgets/reciter/` & `docs/reciter_avatars.md` |
| **`Tafsir` / `Translation`** | **`Synced Lyrics` (متن ترانه)** | `lib/features/tafsir_manager/` |
| **`Bookmarks`** | **`Liked Songs` / `Favorites`** | `lib/features/bookmarks/` |
| **`Topic Studio` (فیش‌برداری)** | **`Custom Playlists Manager`** | `lib/features/topic_studio/` |
| **`MiniAudioPlayerBar`** | **`MusicMiniPlayer`** | `lib/features/mini_audio_player/presentation/widgets/mini_audio_player_bar.dart` |
| **`AppBottomNavBar`** | **`MusicBottomNavBar`** | `lib/features/main_navigation/presentation/widgets/app_bottom_nav_bar.dart` |
| **`AppModalHeader`** | **`MusicModalHeader`** | `lib/common/widgets/app_modal_header.dart` |
| **`AppSegmentedTabBar`** | **`Genre / Mood TabBar`** | `lib/common/widgets/app_segmented_tab_bar.dart` |

---

## ۹. چک‌لیست پیاده‌سازی برای تیم توسعه

- [ ] کپی کردن فایل‌های پایه [`app_dimens.dart`](file:///d:/flutterProjects/quran/lib/core/theme/app_dimens.dart) و [`app_typography.dart`](file:///d:/flutterProjects/quran/lib/core/theme/app_typography.dart) بدون دستکاری مقادیر اصلی.
- [ ] جایگزینی رنگ اکسنت در `app_colors.dart` یا فایل معادل برای تم موسیقی.
- [ ] پیاده‌سازی تمام دیالوگ‌ها و باتم‌شیت‌ها با ویجت [`AppModalHeader`](file:///d:/flutterProjects/quran/lib/common/widgets/app_modal_header.dart) جهت تضمین وسط‌چین بودن تیترها و دکمه ضربدر استاندارد.
- [ ] استفاده انحصاری از آیکون‌های پکیج `CupertinoIcons`.
- [ ] فعال‌سازی `HapticFeedback.selectionClick()` در تمام المان‌های کلیک‌پذیر.
- [ ] تنظیم ارتفاع مینی پلیر روی ۴۴ پیکسل کپسولی معلق با بردر رنگ اکسنت و بلور شیشه‌ای.
