import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/data/remote/tafakor_api_client.dart';
import '../../../../common/widgets/app_cached_network_image.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tafakor/application/controllers/tafakor_auth_controller.dart';
import '../../../tafakor/application/controllers/tafakor_topics_controller.dart';
import '../../../tafakor/domain/entities/tafakor_topic.dart';
import '../../application/controllers/in_drawer_editor_controller.dart';
import '../../domain/entities/topic_block.dart';

import 'package:dio/dio.dart';
import '../../../../common/exceptions/failure.dart';
import '../../../../core/routes/go_router_provider.dart';
import '../../../../core/routes/route_name.dart';
import '../../../tafakor/presentation/ui/tafakor_login_screen.dart';

/// Modal dialog for selecting target Tafakor topic and publishing in-drawer draft.
class SendToTopicDialog extends ConsumerStatefulWidget {
  const SendToTopicDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SendToTopicDialog(),
    );
  }

  @override
  ConsumerState<SendToTopicDialog> createState() => _SendToTopicDialogState();
}

class _SendToTopicDialogState extends ConsumerState<SendToTopicDialog> {
  late final ScrollController _scrollController;
  final Set<int> _selectedTopicIds = {};
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Formats all in-drawer blocks into clean text for publication
  String _formatDraftContent(List<TopicBlock> blocks) {
    return TopicBlock.formatBlocksForPublication(blocks);
  }

  Future<void> _handleSend(List<TafakorTopic> allowedTopics) async {
    setState(() => _errorMessage = null);

    if (_selectedTopicIds.isEmpty) {
      debugPrint('[SendToTopic] No topic selected.');
      setState(() => _errorMessage = 'لطفاً حداقل یک کانال را انتخاب کنید.');
      AppSnackBar.showError(context, 'لطفاً حداقل یک کانال را انتخاب کنید.');
      return;
    }

    final targetTopics = allowedTopics
        .where((t) => _selectedTopicIds.contains(t.id))
        .toList();

    if (targetTopics.isEmpty) {
      setState(() => _errorMessage = 'کانال‌های انتخاب‌شده نامعتبر هستند.');
      return;
    }

    final editorState = ref.read(inDrawerEditorControllerProvider);
    if (editorState.isEmpty) {
      debugPrint('[SendToTopic] Editor state is completely empty.');
      setState(() => _errorMessage = 'پیش‌نویس خالی است.');
      AppSnackBar.showError(context, 'پیش‌نویس خالی است.');
      return;
    }

    final content = _formatDraftContent(editorState.blocks);
    if (content.isEmpty) {
      debugPrint('[SendToTopic] Content is empty after formatting. Blocks count: ${editorState.blocks.length}');
      setState(() => _errorMessage = 'مطلبی برای ارسال وجود ندارد. لطفاً متنی بنویسید.');
      AppSnackBar.showError(context, 'مطلبی برای ارسال وجود ندارد.');
      return;
    }

    debugPrint('[SendToTopic] Starting post to ${targetTopics.length} topics. Length: ${content.length}');
    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    int successCount = 0;
    final List<String> failedTopicNames = [];
    final dio = ref.read(tafakorDioProvider);
    bool authExpired = false;

    for (final targetTopic in targetTopics) {
      try {
        final response = await dio.post(
          'notes/',
          data: {
            'topic': targetTopic.id,
            'content': content,
          },
        );

        debugPrint('[SendToTopic] Topic ${targetTopic.id} response statusCode: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          successCount++;
        } else {
          failedTopicNames.add(targetTopic.name);
        }
      } catch (e, st) {
        debugPrint('[SendToTopic] Exception sending note to topic ${targetTopic.id}: $e\n$st');
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          authExpired = true;
          break;
        }
        failedTopicNames.add(targetTopic.name);
      }
    }

    if (!mounted) return;

    if (authExpired) {
      debugPrint('[SendToTopic] 401/403 detected on sending note. Logging out and redirecting to login.');
      await ref.read(tafakorAuthControllerProvider.notifier).logout();

      if (mounted) {
        Navigator.of(context).pop(false);
      }
      final rootContext = rootNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        AppSnackBar.showError(
          rootContext,
          'نشست کاربری شما منقضی شده است. لطفاً مجدداً وارد شوید.',
        );
        Navigator.of(rootContext).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: tafakorLoginRoute),
            builder: (_) => const TafakorLoginScreen(),
          ),
        );
      }
      return;
    }

    setState(() => _isSending = false);

    if (successCount > 0) {
      HapticFeedback.heavyImpact();
      ref.read(inDrawerEditorControllerProvider.notifier).clearAll();
      ref.invalidate(tafakorTopicsProvider);

      final targetContext = rootNavigatorKey.currentContext;
      Navigator.of(context).pop(true);
      if (targetContext != null && targetContext.mounted) {
        if (failedTopicNames.isEmpty) {
          if (targetTopics.length == 1) {
            AppSnackBar.showSuccess(
              targetContext,
              'مطلب با موفقیت در کانال «${targetTopics.first.name}» منتشر شد.',
            );
          } else {
            AppSnackBar.showSuccess(
              targetContext,
              'مطلب با موفقیت در هر ${successCount.toPersianDigit()} کانال منتشر شد.',
            );
          }
        } else {
          AppSnackBar.showWarning(
            targetContext,
            'مطلب در ${successCount.toPersianDigit()} کانال منتشر شد، اما ارسال به (${failedTopicNames.join('، ')}) با خطا مواجه شد.',
          );
        }
      }
    } else {
      final msg = failedTopicNames.isEmpty
          ? 'خطا در ارسال پست: لطفاً اتصال اینترنت را بررسی کنید.'
          : 'خطا در ارسال پست به کانال‌های انتخاب‌شده.';
      setState(() => _errorMessage = msg);
      AppSnackBar.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final currentUser = ref.watch(tafakorUserProvider);
    final userPhone = currentUser?.phone;
    final topicsAsync = ref.watch(tafakorTopicsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppModalHeader(
                title: 'ارسال به تاپیک',
                onClose: _isSending ? null : () => Navigator.of(context).pop(false),
                showDragHandle: false,
                showDivider: true,
                bottomSpacing: 12,
              ),

              // Content / Topics List
              topicsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: CupertinoActivityIndicator(radius: 13),
                  ),
                ),
                error: (err, stack) {
                  final isUnauthorized = (err is Failure &&
                          (err.statusCode == 401 || err.statusCode == 403)) ||
                      (err is DioException &&
                          (err.response?.statusCode == 401 ||
                              err.response?.statusCode == 403));

                  if (isUnauthorized) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.lock_shield,
                            size: 36,
                            color: colorScheme.error.withValues(alpha: 0.8),
                          ),
                          8.vSpace,
                          Text(
                            'نشست کاربری منقضی شده است',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                          4.vSpace,
                          Text(
                            'برای دریافت کانال‌ها و ارسال مطلب، لطفاً مجدداً وارد شوید.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          14.vSpace,
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await ref
                                  .read(tafakorAuthControllerProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                Navigator.of(context).pop(false);
                              }
                              final rootContext =
                                  rootNavigatorKey.currentContext;
                              if (rootContext != null && rootContext.mounted) {
                                Navigator.of(rootContext).push(
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                        name: tafakorLoginRoute),
                                    builder: (_) => const TafakorLoginScreen(),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              CupertinoIcons.arrow_right_to_line,
                              size: 16,
                            ),
                            label: const Text(
                              'ورود مجدد',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.wifi_exclamationmark,
                          size: 32,
                          color: colorScheme.error.withValues(alpha: 0.8),
                        ),
                        8.vSpace,
                        Text(
                          'خطا در دریافت کانال‌ها',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        10.vSpace,
                        OutlinedButton(
                          onPressed: () => ref.invalidate(tafakorTopicsProvider),
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  );
                },
                data: (allTopics) {
                  final allowedTopics = allTopics.where((t) {
                    return t.isOwner(userPhone) ||
                        (currentUser != null && false);
                  }).toList();

                  if (allowedTopics.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.tray,
                            size: 36,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          10.vSpace,
                          Text(
                            'کانالی با دسترسی ارسال یافت نشد',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          4.vSpace,
                          Text(
                            'برای ارسال پست، ابتدا باید در تفکر کانال داشته باشید.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final showScrollbar = allowedTopics.length > 3;
                  final allSelected = _selectedTopicIds.length == allowedTopics.length;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (allowedTopics.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _isSending
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (allSelected) {
                                          _selectedTopicIds.clear();
                                        } else {
                                          _selectedTopicIds.addAll(
                                            allowedTopics.map((t) => t.id),
                                          );
                                        }
                                        _errorMessage = null;
                                      });
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                child: Text(
                                  allSelected ? 'لغو همه' : 'انتخاب همه',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: (MediaQuery.sizeOf(context).height * 0.42).clamp(180.0, 360.0),
                        ),
                        child: RawScrollbar(
                          controller: _scrollController,
                          thumbVisibility: showScrollbar,
                          thickness: 3.5,
                          radius: const Radius.circular(8),
                          thumbColor: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.20),
                          padding: const EdgeInsets.only(left: 2),
                          child: ListView.separated(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 6, right: 1, top: 2, bottom: 2),
                            itemCount: allowedTopics.length,
                            separatorBuilder: (_, _) => 8.vSpace,
                            itemBuilder: (context, index) {
                              final topic = allowedTopics[index];
                              final isSelected = _selectedTopicIds.contains(topic.id);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isSending
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            if (isSelected) {
                                              _selectedTopicIds.remove(topic.id);
                                            } else {
                                              _selectedTopicIds.add(topic.id);
                                            }
                                            _errorMessage = null;
                                          });
                                        },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary.withValues(
                                              alpha: isDark ? 0.20 : 0.10,
                                            )
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.03)
                                              : Colors.black.withValues(alpha: 0.02)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        // Topic Image / Avatar
                                        AppCachedNetworkImage(
                                          imageUrl: topic.fullImageUrl,
                                          width: 36,
                                          height: 36,
                                          borderRadius: BorderRadius.circular(9),
                                          fallbackText: topic.name,
                                          fallbackIcon: null,
                                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                                        ),
                                        12.hSpace,
                                        // Title & Post Badge / Active Bot Channels
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                topic.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: AppTypography.fontFamily,
                                                  fontSize: 13.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? (isDark
                                                          ? Colors.white
                                                          : colorScheme.primary)
                                                      : colorScheme.onSurface,
                                                ),
                                              ),
                                              if ((topic.postBadge != null &&
                                                      topic.postBadge!.isNotEmpty) ||
                                                  topic.telegramBotActive ||
                                                  topic.baleBotActive) ...[
                                                3.5.vSpace,
                                                Wrap(
                                                  spacing: 5,
                                                  runSpacing: 4,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    if (topic.postBadge != null &&
                                                        topic.postBadge!.isNotEmpty)
                                                      Text(
                                                        topic.postBadge!,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppTypography.fontFamily,
                                                          fontSize: 10.5,
                                                          color: colorScheme.primary
                                                              .withValues(alpha: 0.8),
                                                        ),
                                                      ),
                                                    if (topic.telegramBotActive)
                                                      _buildChannelBadge(
                                                        assetPath: AppConstants
                                                            .telegramLogoAsset,
                                                        label: 'تلگرام',
                                                        colorScheme: colorScheme,
                                                        isDark: isDark,
                                                      ),
                                                    if (topic.baleBotActive)
                                                      _buildChannelBadge(
                                                        assetPath: AppConstants
                                                            .baleLogoAsset,
                                                        label: 'بله',
                                                        colorScheme: colorScheme,
                                                        isDark: isDark,
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        8.hSpace,
                                        // Standalone green checkmark (no circle)
                                        AnimatedOpacity(
                                          duration: const Duration(milliseconds: 180),
                                          opacity: isSelected ? 1.0 : 0.0,
                                          child: Icon(
                                            CupertinoIcons.checkmark_alt,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Inline error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                      8.hSpace,
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                10.vSpace,
              ] else ...[
                14.vSpace,
              ],

              // Action Buttons: انصراف & ارسال
              topicsAsync.maybeWhen(
                data: (allTopics) {
                  final allowedTopics = allTopics.where((t) {
                    return t.isOwner(userPhone);
                  }).toList();

                  if (allowedTopics.isEmpty) {
                    return TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'بستن',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSending
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            'انصراف',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      10.hSpace,
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSending
                              ? null
                              : () => _handleSend(allowedTopics),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.paperplane_fill,
                                  size: 14,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSending
                                ? 'در حال ارسال...'
                                : (_selectedTopicIds.length <= 1
                                    ? 'ارسال پست'
                                    : 'ارسال به ${_selectedTopicIds.length.toPersianDigit()} کانال'),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelBadge({
    required String assetPath,
    required String label,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 12.5,
            height: 12.5,
            fit: BoxFit.contain,
          ),
          3.5.hSpace,
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
