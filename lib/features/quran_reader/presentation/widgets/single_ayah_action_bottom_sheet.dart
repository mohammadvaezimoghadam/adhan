import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/extensions/ayah_extension.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/go_router_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../bookmarks/application/controllers/bookmarks_controller.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../application/controllers/selected_ayah_action_provider.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../../tafsir_manager/presentation/widgets/tafsir_selection_dialog.dart';
import '../utils/reciter_download_helper.dart';
import 'word_by_word_bottom_sheet.dart';

/// Luxury bottom sheet displayed when a user long-presses an Ayah.
/// Houses single-ayah quick actions: Copy, Share, Word-by-word Dictionary,
/// and Bookmark Ayah.
class SingleAyahActionBottomSheet extends ConsumerWidget {
  final AyahEntity ayah;
  final String surahName;
  final int totalAyahsInSurah;

  const SingleAyahActionBottomSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.totalAyahsInSurah,
  });

  static Future<void> show(
    BuildContext context, {
    required AyahEntity ayah,
    required String surahName,
    required int totalAyahsInSurah,
  }) {
    if (context.isWideScreen) {
      return showDialog(
        context: context,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: SingleAyahActionBottomSheet(
                  ayah: ayah,
                  surahName: surahName,
                  totalAyahsInSurah: totalAyahsInSurah,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleAyahActionBottomSheet(
        ayah: ayah,
        surahName: surahName,
        totalAyahsInSurah: totalAyahsInSurah,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if this specific Ayah is currently bookmarked
    final isBookmarked = ref.watch(
      bookmarksControllerProvider.select(
        (list) => list.any(
          (b) => b.surahId == ayah.surahId && b.ayahNumber == ayah.ayahNumber,
        ),
      ),
    );

    // Audio playback status for this Ayah
    final isAudioForThisSurah = ref.watch(
      quranAudioControllerProvider.select(
        (s) => s.currentSurahId == ayah.surahId,
      ),
    );
    final isPlayingAyah = isAudioForThisSurah &&
        ref.watch(
          activeAyahProvider.select((active) => active == ayah.ayahNumber),
        );
    final isAudioPlayingNow = isPlayingAyah &&
        ref.watch(
          quranAudioControllerProvider.select(
            (s) => s.status == AudioStatus.playing,
          ),
        );

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final sheetBg = colors.dialogSurface;
    final cardBg = colors.cardBackground;
    final borderColor = colors.cardBorder;
    final primaryColor = colorScheme.primary;
    final cleanSurahName = surahName.replaceAll('سوره', '').trim();

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppModalHeader(
                showDragHandle: true,
                title: 'سوره $cleanSurahName • آیه ${ayah.ayahNumber.toPersianDigit()}',
                bottomSpacing: 14,
              ),

              // Row 1: Study & Listening (پخش، تفسیر، لغت‌نامه)
              Row(
                children: [
                  // Action 1: Play / Pause Ayah (پخش / توقف آیه)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: isAudioPlayingNow ? primaryColor : borderColor,
                      icon: isAudioPlayingNow
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      iconColor: isAudioPlayingNow ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                      label: isAudioPlayingNow ? 'توقف' : 'پخش',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);

                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();

                        final controller = container.read(quranAudioControllerProvider.notifier);
                        if (isAudioPlayingNow) {
                          controller.pause();
                        } else {
                          final isReady = await ReciterDownloadHelper.checkAndPromptForPlayback(
                            context: navContext,
                            surahId: ayah.surahId,
                          );
                          if (isReady) {
                            controller.resumeAutoScrollAndSync();
                            controller.playAyah(
                              surahId: ayah.surahId,
                              ayahNumber: ayah.ayahNumber,
                              totalAyahsInSurah: totalAyahsInSurah,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  8.hSpace,

                  // Action 2: Tafsir (تفسیر آیه)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      iconWidget: SvgPicture.asset(
                        'assets/icons/ic_tafsir.svg',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white70 : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'تفسیر',
                      onTap: () {
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);
                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();

                        TafsirSelectionDialog.show(
                          navContext,
                          ayah: ayah,
                          surahName: cleanSurahName,
                        );
                      },
                    ),
                  ),
                  8.hSpace,

                  // Action 3: Dictionary / Word by Word (لغت‌نامه)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      icon: CupertinoIcons.book,
                      iconColor: isDark ? Colors.white70 : Colors.black87,
                      label: 'لغت‌نامه',
                      onTap: () {
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);
                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();
                        WordByWordBottomSheet.show(
                          navContext,
                          surahId: ayah.surahId,
                          surahName: cleanSurahName,
                          ayahNumber: ayah.ayahNumber,
                        );
                      },
                    ),
                  ),
                ],
              ),
              8.vSpace,

              // Row 2: Utilities & Actions (نشانه‌گذاری، کپی، اشتراک)
              Row(
                children: [
                  // Action 4: Bookmark Ayah (نشانه‌گذاری آیه)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      icon: isBookmarked
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      iconColor: isBookmarked ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                      label: isBookmarked ? 'نشان‌شده' : 'نشانه‌گذاری',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);

                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();
                        final isAdded = await container
                            .read(bookmarksControllerProvider.notifier)
                            .toggleBookmark(
                              surahId: ayah.surahId,
                              surahName: surahName,
                              ayahNumber: ayah.ayahNumber,
                              totalAyahs: totalAyahsInSurah,
                              arabicText: ayah.arabicText,
                              isAyahBookmark: true,
                            );

                        final snackContext = rootNavigatorKey.currentContext;
                        if (snackContext != null && snackContext.mounted) {
                          if (isAdded) {
                            AppSnackBar.showSuccess(
                              snackContext,
                              'آیه ${ayah.ayahNumber.toPersianDigit()} سوره $cleanSurahName نشانه‌گذاری شد.',
                            );
                          } else {
                            AppSnackBar.showInfo(
                              snackContext,
                              'نشانه آیه ${ayah.ayahNumber.toPersianDigit()} حذف شد.',
                            );
                          }
                        }
                      },
                    ),
                  ),
                  8.hSpace,

                  // Action 5: Copy (کپی آیه)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      icon: CupertinoIcons.doc_on_doc,
                      iconColor: isDark ? Colors.white70 : Colors.black87,
                      label: 'کپی آیه',
                      onTap: () async {
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);
                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();

                        final removeBrackets = container
                            .read(quranDisplaySettingsControllerProvider)
                            .removeTranslationBrackets;

                        final formatted = ayah.toShareableText(
                          surahName: cleanSurahName,
                          removeBrackets: removeBrackets,
                        );

                        await Clipboard.setData(ClipboardData(text: formatted));
                        final snackContext = rootNavigatorKey.currentContext;
                        if (snackContext != null && snackContext.mounted) {
                          AppSnackBar.showSuccess(
                            snackContext,
                            'آیه ${ayah.ayahNumber.toPersianDigit()} سوره $cleanSurahName کپی شد.',
                          );
                        }
                      },
                    ),
                  ),
                  8.hSpace,

                  // Action 6: Share (اشتراک‌گذاری)
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      icon: CupertinoIcons.share,
                      iconColor: isDark ? Colors.white70 : Colors.black87,
                      label: 'اشتراک',
                      onTap: () async {
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        final container = ProviderScope.containerOf(navContext, listen: false);
                        Navigator.of(context).pop();
                        container.read(selectedAyahActionProvider.notifier).clearSelection();

                        final removeBrackets = container
                            .read(quranDisplaySettingsControllerProvider)
                            .removeTranslationBrackets;

                        final formatted = ayah.toShareableText(
                          surahName: cleanSurahName,
                          removeBrackets: removeBrackets,
                        );

                        await Share.share(
                          formatted,
                          subject: 'آیه ${ayah.ayahNumber} سوره $cleanSurahName',
                        );
                      },
                    ),
                  ),
                ],
              ),
              6.vSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null)
                  SizedBox(
                    width: 21,
                    height: 21,
                    child: Center(child: iconWidget),
                  )
                else if (icon != null)
                  Icon(icon, size: 21, color: iconColor),
                5.vSpace,
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF4A463F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
