import '../../domain/entities/tafsir_entity.dart';

/// Catalog of authentic Iranian/Persian and Islamic Quran Exegeses (Tafsirs).
/// All entries are 100% downloadable on demand from stable high-speed CDNs.
class TafsirCatalog {
  static const List<TafsirEntity> allTafsirs = [
    TafsirEntity(
      id: 'tafsir.nemouneh',
      name: 'تفسیر نمونه',
      authorName: 'آیت‌الله العظمی ناصر مکارم شیرازی',
      description: 'تفسیر جامع، روان و اجتماعی ۲۷ جلدی قرآن کریم به زبان فارسی',
      sourceUrl: 'https://cdn.jsdelivr.net/gh/app-furqan/quran-app-data@main/data/tafsir_nemouneh_fa_en_ur.tar.xz',
    ),
    TafsirEntity(
      id: 'tafsir.noor',
      name: 'تفسیر نور',
      authorName: 'حجت‌الاسلام والمسلمین محسن قرائتی',
      description: 'نکات اخلاقی، تربیتی و پیام‌های کاربردی آیات زندگی (۱۰ جلدی)',
      sourceUrl: 'https://cdn.jsdelivr.net/gh/app-furqan/quran-app-data@main/data/tafsir-noor.tar.xz',
    ),
    TafsirEntity(
      id: 'tafsir.almizan',
      name: 'تفسیر المیزان',
      authorName: 'علامه سید محمدحسین طباطبایی',
      description: 'تفسیر اجتهادی و عمیق قرآن به قرآن (ترجمه فارسی ۲۰ جلدی)',
      sourceUrl: 'https://cdn.jsdelivr.net/gh/app-furqan/quran-app-data@main/data/tafsir_almizan_fa.db.tar.xz',
    ),
  ];
}
