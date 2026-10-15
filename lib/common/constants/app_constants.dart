
abstract class AppConstants {
  // Base URLs
  static const String alQuranCloudBaseUrl = 'https://api.alquran.cloud/v1';
  static const String ummahApiBaseUrl = 'https://ummahapi.com/api';
  static const String everyAyahAudioBaseUrl = 'https://www.everyayah.com/data';
  // Production (سرور اصلی تفکر):
  static const String tafakorBaseUrl = 'https://tafakormag.ir/api/';
  // Local Docker (اتصال به داکر لوکال روی پورت 8085):
  // static String get tafakorBaseUrl {
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2:8085/api/';
  //   }
  //   return 'http://127.0.0.1:8085/api/';
  // }

  // OTA Patch Server (اتصال به سرور پروداکشن)
  // OTA Patch Server (قابلیت تنظیم داینامیک با --dart-define=OTA_SERVER_URL=... یا اتصال پیش‌فرض به سرور)
  static const String patchServerBaseUrl = String.fromEnvironment(
    'OTA_SERVER_URL',
    defaultValue: 'http://5.22.203.61',
  );

  static const String patchAppId = 'quran_tafakor';
  static const String patchChannel = 'stable';

  // Assets Paths
  static const String ayahCardBgAsset = 'assets/images/ayah_card_bg.png';
  static const String splashBgAsset = 'assets/images/splash_bg.jpg';
  static const String telegramLogoAsset = 'assets/icons/telegram_logo.png';
  static const String baleLogoAsset = 'assets/icons/bale_logo.png';

  // Network Error Messages - Connection Types
  static const String connectionTimeoutError =
      'زمان اتصال به سرور به پایان رسید. لطفاً مجدداً تلاش کنید.';
  static const String sendTimeoutError =
      'زمان ارسال اطلاعات به سرور به پایان رسید. اتصال اینترنت خود را بررسی کنید.';
  static const String receiveTimeoutError =
      'زمان دریافت پاسخ از سرور به پایان رسید. لطفاً مجدداً تلاش کنید.';
  static const String badCertificateError = 'گواهی امنیتی سرور معتبر نمی‌باشد.';
  static const String requestCancelledError = 'درخواست لغو شد.';
  static const String connectionError =
      'اتصال با سرور برقرار نشد. لطفاً اینترنت خود را بررسی کنید.';
  static const String unexpectedError =
      'خطای غیرمنتظره‌ای رخ داد. لطفاً بعداً تلاش کنید.';

  // Network Error Messages - HTTP Status Codes
  static const String badRequestError = 'درخواست نامعتبر است.';
  static const String unauthorizedError =
      'دسترسی غیرمجاز. لطفاً وارد حساب کاربری شوید.';
  static const String forbiddenError = 'شما دسترسی به این بخش را ندارید.';
  static const String notFoundError = 'اطلاعات مورد نظر یافت نشد.';
  static const String tooManyRequestsError =
      'تعداد درخواست‌ها بیش از حد مجاز است. لطفاً کمی صبر کنید.';
  static const String internalServerError =
      'خطای داخلی سرور. لطفاً بعداً تلاش کنید.';
  static const String serviceUnavailableError =
      'سرویس در حال حاضر در دسترس نیست.';

  // Tafakor Feature Error Messages
  static const String tafakorUserFetchError =
      'خطا در بازیابی اطلاعات کاربر تفکر';
  static const String tafakorUserNotLoggedIn = 'کاربر وارد نشده است.';
  static const String tafakorProfileFetchError =
      'خطا در دریافت اطلاعات پروفایل';
  static const String tafakorLogoutError = 'خطا در خروج از حساب کاربری تفکر';

  // Home & Surah Feature Error Messages
  static const String incompleteAyahDataError =
      'اطلاعات آیه روز کامل دریافت نشد.';
  static const String ayahOfTheDayFetchError =
      'خطای غیرمنتظره در دریافت آیه روز';
  static const String surahFetchError = 'خطایی در دریافت لیست سوره‌ها رخ داد';
  static const String surahFetchUnexpectedError =
      'خطای غیرمنتظره‌ای در دریافت سوره‌ها رخ داد.';

  // UI App Titles & Theme Tooltips
  static const String appTitle = 'قرآن تفکر';
  static const String surahListScreenTitle = 'فهرست سوره‌ها';
  static const String lightThemeTooltip = 'تم روشن';
  static const String darkThemeTooltip = 'تم تاریک';

  // UI Common String Constants
  static const String ayahOfTheDayTitle = 'آیه روز';
  static const String loadingAyahOfTheDay = 'در حال دریافت آیه روز...';
  static const String retryButtonLabel = 'تلاش مجدد';
  static const String readMoreButtonLabel = 'مشاهده بیشتر';
  static const String collapseButtonLabel = 'بستن';
  static const String surahLabel = 'سوره';
  static const String ayahLabel = 'آیه';
  static const String meccamTypeLabel = 'مکی';
  static const String medinanTypeLabel = 'مدنی';

  // Home Quick Access Titles & Messages
  static const String quickAccessTitle = 'دسترسی سریع';
  static const String surahListTitle = 'سوره‌ها';
  static const String translationTitle = 'ترجمه';
  static const String settingsTitle = 'تنظیمات';
  static const String homeWelcomeTitle = 'به اپلیکیشن قرآن تفکر خوش آمدید';
  static const String translationComingSoon = 'بخش ترجمه به زودی اضافه می‌شود';
  static const String settingsComingSoon = 'بخش تنظیمات به زودی اضافه می‌شود';

  // Translation Selection Bottom Sheet
  static const String selectSurahAndTranslatorTitle = 'انتخاب سوره و مترجم';
  static const String translatorLabel = 'مترجم';
  static const String startReadingButtonLabel = 'شروع مطالعه';
  static const String showArabicTextToggleLabel = 'نمایش متن عربی';

  // Surah List & Quran Reader Feature Constants
  static const String surahListErrorTitle = 'خطا در بارگذاری اطلاعات';
  static const String noSurahFound = 'سوره‌ای با این مشخصات یافت نشد.';
  static const String ayahLoadError = 'خطا در بارگذاری آیات';
  static const String noAyahFound = 'آیه‌ای یافت نشد.';
  static const String searchHintText = 'جستجوی نام یا شماره سوره...';

  // Reciter & Audio Playback Constants
  static const String selectReciterTitle = 'انتخاب قاری قرآن';
  static const String searchReciterHint = 'جستجوی قاری...';
  static const String noReciterFound = 'هیچ قاری با این مشخصات یافت نشد.';
  static const String reciterLoadError = 'خطا در بارگذاری لیست قاریان';
  static const String defaultReciterSubtitle = 'قاری پیش‌فرض (شهریار پرهیزگار)';
  static const String recitersCountLabel = 'تعداد قاریان:';
  static const String closeButtonLabel = 'بستن';
  static const String nowPlayingLabel = 'در حال پخش...';
  static const String bufferingAudioLabel = 'در حال دریافت صوت...';
  static const String audioPlaybackError = 'خطا در پخش صوت';
  static const String selectReciterButtonLabel = 'انتخاب قاری';
  static const String copyAyahTooltip = 'کپی متن آیه';
  static const String shareAyahTooltip = 'اشتراک‌گذاری آیه';
  static const String playAyahTooltip = 'پخش آیه';
  static const String copyAyahSuccessMessage = 'متن آیه با موفقیت کپی شد';

  // Page Navigation Feature
  static const String pageNotFoundError = 'اطلاعاتی برای این صفحه یافت نشد.';
  static const String invalidScannedCodeError =
      'کد اسکن شده معتبر نیست یا صفحه وجود ندارد.';
  static const String telavatNoorPlan = 'طرح تلاوت نور';
  static const String pageNavigationTitle = 'پرش به صفحه';

  /// Map of Surah number (1..114) to its traditional historical revelation order (1..114)
  static const Map<int, int> surahRevelationOrderMap = {
    1: 5,
    2: 87,
    3: 89,
    4: 92,
    5: 112,
    6: 55,
    7: 39,
    8: 88,
    9: 113,
    10: 51,
    11: 52,
    12: 53,
    13: 96,
    14: 72,
    15: 54,
    16: 70,
    17: 50,
    18: 69,
    19: 44,
    20: 45,
    21: 73,
    22: 103,
    23: 74,
    24: 102,
    25: 42,
    26: 47,
    27: 48,
    28: 49,
    29: 85,
    30: 84,
    31: 57,
    32: 75,
    33: 90,
    34: 58,
    35: 43,
    36: 41,
    37: 56,
    38: 38,
    39: 59,
    40: 60,
    41: 61,
    42: 62,
    43: 63,
    44: 64,
    45: 65,
    46: 66,
    47: 95,
    48: 111,
    49: 106,
    50: 34,
    51: 67,
    52: 76,
    53: 23,
    54: 37,
    55: 97,
    56: 46,
    57: 94,
    58: 105,
    59: 101,
    60: 91,
    61: 109,
    62: 110,
    63: 104,
    64: 108,
    65: 99,
    66: 107,
    67: 77,
    68: 2,
    69: 78,
    70: 79,
    71: 71,
    72: 40,
    73: 3,
    74: 4,
    75: 31,
    76: 98,
    77: 33,
    78: 80,
    79: 81,
    80: 24,
    81: 7,
    82: 82,
    83: 86,
    84: 83,
    85: 27,
    86: 36,
    87: 8,
    88: 68,
    89: 10,
    90: 35,
    91: 26,
    92: 9,
    93: 11,
    94: 12,
    95: 28,
    96: 1,
    97: 25,
    98: 100,
    99: 93,
    100: 14,
    101: 30,
    102: 16,
    103: 13,
    104: 32,
    105: 19,
    106: 29,
    107: 17,
    108: 15,
    109: 18,
    110: 114,
    111: 6,
    112: 22,
    113: 20,
    114: 21,
  };
}
