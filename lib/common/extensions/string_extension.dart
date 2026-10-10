extension StringSearchNormalizeExtension on String {
  /// Removes text inside brackets [...], (...), {...} and cleans up resulting multiple spaces.
  /// Used primarily for cleaning up translator explanations from Quran translations.
  String removeTranslatorExplanations() {
    final regex = RegExp(r'[\(\[\{\（\［\｛].*?[\)\]\}\）\］\｝]');
    String cleanText = replaceAll(regex, '');
    // Clean up orphan spaces before punctuation (e.g. " ." -> ".")
    cleanText = cleanText.replaceAllMapped(RegExp(r'\s+([.,;:؛،!؟])'), (match) => match[1]!);
    return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Normalizes Arabic and Persian text for flexible search matching.
  /// Removes Tashkeel (harakat), unifies Arabic letter variants (ي/ى->ی, ك->ک, أ/إ/آ/ٱ->ا, ة->ه, ؤ->و, ئ->ی),
  /// converts Arabic/Persian digits to standard digits, and lowercases text.
  String normalizeForSearch() {
    if (isEmpty) return '';

    String text = this;

    // 1. Remove Tashkeel (diacritics / harakat) & Quranic stop marks
    text = text.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'),
      '',
    );

    // 2. Unify Arabic character variants to Persian/Standard equivalents
    text = text
        .replaceAll(RegExp(r'[يى]'), 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ی');

    // 3. Convert Arabic and Persian digits to standard ASCII digits
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], i.toString());
      text = text.replaceAll(persianDigits[i], i.toString());
    }

    return text.toLowerCase().trim();
  }

  /// Converts English digits in a String to Persian digits.
  String toPersianDigit() {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    // Persian digits ۰-۹ represented as Unicode escapes to ensure safe encoding across all environments
    const persian = [
      '\u06F0', '\u06F1', '\u06F2', '\u06F3', '\u06F4',
      '\u06F5', '\u06F6', '\u06F7', '\u06F8', '\u06F9',
    ];

    String text = this;
    for (int i = 0; i < english.length; i++) {
      text = text.replaceAll(english[i], persian[i]);
    }
    return text;
  }

  /// Converts Persian and Arabic digits in a String to standard English ASCII digits.
  String toEnglishDigit() {
    // Arabic digits ٠-٩ and Persian digits ۰-۹
    const arabic = [
      '\u0660', '\u0661', '\u0662', '\u0663', '\u0664',
      '\u0665', '\u0666', '\u0667', '\u0668', '\u0669',
    ];
    const persian = [
      '\u06F0', '\u06F1', '\u06F2', '\u06F3', '\u06F4',
      '\u06F5', '\u06F6', '\u06F7', '\u06F8', '\u06F9',
    ];

    String text = this;
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabic[i], i.toString());
      text = text.replaceAll(persian[i], i.toString());
    }
    return text;
  }
}
