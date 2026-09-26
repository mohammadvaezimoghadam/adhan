import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/payment/i_payment_service.dart';
import '../../../core/services/payment/models/payment_product.dart';
import '../../../core/services/payment/models/purchase_result.dart';
import '../../../core/services/payment/payment_providers.dart';
import '../data/vip_secure_storage.dart';
import '../domain/models/vip_subscription_state.dart';
import '../domain/policy/audio_vip_policy.dart';

/// Provider for the secure storage instance.
final vipSecureStorageProvider = Provider<VipSecureStorage>((ref) {
  return const VipSecureStorage();
});

/// Riverpod Notifier controlling VIP audio subscriptions and license checks.
class VipSubscriptionController extends Notifier<VipSubscriptionState> {
  late final IPaymentService _paymentService;
  late final VipSecureStorage _storage;

  Timer? _periodicSyncTimer;
  Timer? _exactExpiryTimer;
  AppLifecycleListener? _lifecycleListener;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'VipSubscription', error: error, stackTrace: stackTrace);
    debugPrint('[VipSubscription] $message');
  }

  @override
  VipSubscriptionState build() {
    _paymentService = ref.watch(paymentServiceProvider);
    _storage = ref.watch(vipSecureStorageProvider);

    _log('🚀 [Init] Initializing VipSubscriptionController...');
    _loadPersistedState().then((_) async {
      await syncWithStore();
      await fetchLiveProducts();
    });

    _startPeriodicVerification();

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _log('📱 [App Resume] App returned to foreground, checking subscription status with Cafe Bazaar...');
        syncWithStore();
      },
    );

    ref.onDispose(() {
      _periodicSyncTimer?.cancel();
      _exactExpiryTimer?.cancel();
      _lifecycleListener?.dispose();
    });

    return const VipSubscriptionState(isLoading: true);
  }

  /// Starts periodic background check with Cafe Bazaar to detect subscription expirations.
  void _startPeriodicVerification() {
    _periodicSyncTimer?.cancel();
    // Verify every 20 seconds while user is active in the app
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (state.isVip) {
        syncWithStore();
      }
    });
  }

  /// Schedules a timer to revoke VIP the exact second the expiration timestamp is reached.
  void _scheduleExactExpiryTimer(DateTime? expiryDate) {
    _exactExpiryTimer?.cancel();
    if (expiryDate == null) return;

    final diff = expiryDate.difference(DateTime.now());
    if (diff.isNegative) {
      _handleLocalExpiry();
    } else {
      _exactExpiryTimer = Timer(diff, () {
        _log('⏰ [Exact Expiry Timer] VIP expiration timestamp reached!');
        _handleLocalExpiry();
        syncWithStore();
      });
    }
  }

  Future<void> _handleLocalExpiry() async {
    _log('🔒 [Expiry Calculation] Revoking local VIP access because expiration date passed.');
    await _storage.setIsVip(false);
    await _storage.setActivePlanId(null);
    state = state.copyWith(isVip: false, activePlanId: null);
  }

  /// Loads subscription status securely from device storage and enforces expiry.
  Future<void> _loadPersistedState() async {
    try {
      _log('📱 [App Startup] Reading subscription state from local secure storage...');
      final isVip = await _storage.getIsVip();
      var vipExpiry = await _storage.getVipExpiryDate();
      final activePlanId = await _storage.getActivePlanId();
      final purchaseToken = await _storage.getPurchaseToken();

      _log('💾 [Local Storage State]:');
      _log('   ↳ isVip in storage: $isVip');
      _log('   ↳ activePlanId: $activePlanId');
      _log('   ↳ vipExpiryDate: $vipExpiry');
      _log('   ↳ purchaseToken: ${purchaseToken != null ? (purchaseToken.length > 12 ? "${purchaseToken.substring(0, 12)}..." : purchaseToken) : "none"}');

      final now = DateTime.now();
      bool isVipActive = isVip;

      // Check if subscription has expired or has abnormal accumulated duration
      if (vipExpiry != null) {
        // Clamp if accumulated beyond plan duration
        final matchedProduct = activePlanId != null
            ? PaymentProduct.allSubscriptions.where((p) => p.id == activePlanId).firstOrNull
            : null;
        final allowedDays = matchedProduct?.durationDays ?? 30;
        final maxAllowed = now.add(Duration(days: allowedDays));
        if (vipExpiry.isAfter(maxAllowed)) {
          _log('✂️ [Expiry Clamp] Clamping abnormal accumulated expiry ($vipExpiry) to plan duration ($allowedDays days).');
          vipExpiry = maxAllowed;
          await _storage.setVipExpiryDate(vipExpiry);
        }

        final diff = vipExpiry.difference(now);
        if (diff.isNegative) {
          final minsAgo = (-diff.inSeconds / 60).toStringAsFixed(1);
          _log('⏰ [Expiry Calculation] Local subscription has EXPIRED! (Expired $minsAgo minutes ago on $vipExpiry).');
          _log('🔒 [Expiry Calculation] Revoking local VIP access because expiration date passed.');
          isVipActive = false;
          await _storage.setIsVip(false);
        } else {
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          final mins = diff.inMinutes % 60;
          final secs = diff.inSeconds % 60;
          _log('⏳ [Expiry Calculation] Local subscription is ACTIVE! Remaining: ${days}d ${hours}h ${mins}m ${secs}s (Expires at $vipExpiry)');
        }
      } else if (isVip) {
        _log('⏳ [Expiry Calculation] Subscription is Lifetime / Open-ended active.');
      } else {
        _log('ℹ️ [Expiry Calculation] No active VIP subscription in local storage.');
      }

      final cachedProducts = await _storage.getCachedProducts();
      final productsToDisplay = (cachedProducts != null && cachedProducts.isNotEmpty)
          ? cachedProducts
          : PaymentProduct.allSubscriptions;

      state = state.copyWith(
        isVip: isVipActive,
        vipExpiryDate: vipExpiry,
        activePlanId: activePlanId,
        availableProducts: productsToDisplay,
        isLoading: false,
      );
      if (isVipActive && vipExpiry != null) {
        _scheduleExactExpiryTimer(vipExpiry);
      }
      _log('🎯 [Local State Ready] Controller initialized with isVip=$isVipActive (Plan: $activePlanId, Products: ${productsToDisplay.length}). UI unlocked accordingly.');
    } catch (e, stack) {
      _log('❌ Error loading persisted subscription state: $e', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری اطلاعات اشتراک',
      );
    }
  }

  bool _isFetchingProducts = false;
  bool _isSyncing = false;

  /// Fetches live prices and details from Bazaar.
  Future<void> fetchLiveProducts() async {
    if (_isFetchingProducts) return;
    _isFetchingProducts = true;
    try {
      final skuIds = PaymentProduct.allSubscriptions.map((p) => p.id).toList();
      _log('🔍 [Live Products] Fetching live SKU details from Bazaar: $skuIds');
      final liveProducts = await _paymentService.getSubscriptionProducts(skuIds);
      if (liveProducts.isNotEmpty) {
        _log('📦 [Live Products] Updated available products list with ${liveProducts.length} items from Bazaar.');
        await _storage.setCachedProducts(liveProducts);
        state = state.copyWith(availableProducts: liveProducts);
      }
    } catch (e, stack) {
      _log('❌ Error fetching live SKU details: $e', error: e, stackTrace: stack);
    } finally {
      _isFetchingProducts = false;
    }
  }

  /// Background sync to verify active subscriptions with Cafe Bazaar.
  Future<void> syncWithStore() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      _log('🔄 [Bazaar Sync] Querying Cafe Bazaar for live active subscriptions...');
      final isConnected = await _paymentService.isConnected();
      _log('   ↳ Cafe Bazaar connected: $isConnected');

      final purchasedIds = await _paymentService.getPurchasedProductIds();
      _log('📥 [Bazaar Sync Response] Subscribed product IDs from Bazaar: $purchasedIds');

      final now = DateTime.now();
      if (purchasedIds.isNotEmpty) {
        final activeId = purchasedIds.first;
        _log('✅ [Bazaar Sync] Active subscription confirmed by Cafe Bazaar: $purchasedIds');

        final matchedProduct = PaymentProduct.allSubscriptions
            .where((p) => p.id == activeId)
            .firstOrNull;
        final planDays = matchedProduct?.durationDays ?? 30;

        DateTime? targetExpiry = state.vipExpiryDate;
        if (targetExpiry == null || targetExpiry.difference(now).inDays > planDays) {
          targetExpiry = now.add(Duration(days: planDays));
          await _storage.setVipExpiryDate(targetExpiry);
        }

        if (!state.isVip || state.activePlanId != activeId || state.vipExpiryDate != targetExpiry) {
          _log('🔄 [Bazaar Sync] Updating local storage with Bazaar subscription: $activeId (Expiry: $targetExpiry)');
          await _storage.setIsVip(true);
          await _storage.setActivePlanId(activeId);
          state = state.copyWith(
            isVip: true,
            activePlanId: activeId,
            vipExpiryDate: targetExpiry,
          );
          _log('💾 [Bazaar Sync] Local storage updated successfully to active VIP.');
        } else {
          _log('✨ [Bazaar Sync] Local subscription is already in sync with Cafe Bazaar.');
        }
      } else {
        _log('ℹ️ [Bazaar Sync Response] Cafe Bazaar returned 0 active subscriptions for this account.');

        if (isConnected && state.isVip) {
          _log('⚠️ [Bazaar Sync] Subscription is NO LONGER active in Cafe Bazaar (expired/cancelled in Bazaar)!');
          _log('🔒 [Bazaar Sync] Revoking local VIP access to match Cafe Bazaar server status.');
          _exactExpiryTimer?.cancel();
          await _storage.setIsVip(false);
          await _storage.setActivePlanId(null);
          await _storage.setVipExpiryDate(null);
          state = state.copyWith(isVip: false, activePlanId: null, vipExpiryDate: null);
          _log('💾 [Bazaar Sync] Local storage updated: isVip=false.');
        } else if (state.isVip && state.vipExpiryDate != null && now.isAfter(state.vipExpiryDate!)) {
          _log('⏰ [Bazaar Sync] Local subscription expired on ${state.vipExpiryDate}. Revoking local VIP.');
          _exactExpiryTimer?.cancel();
          await _storage.setIsVip(false);
          await _storage.setActivePlanId(null);
          await _storage.setVipExpiryDate(null);
          state = state.copyWith(isVip: false, activePlanId: null, vipExpiryDate: null);
        } else if (state.isVip) {
          _log('🛡️ [Bazaar Sync] Offline or Bazaar not responding; preserving local offline grace period until ${state.vipExpiryDate}.');
        }
      }
    } catch (e, stack) {
      _log('❌ [Bazaar Sync Error] Failed to sync with Cafe Bazaar: $e', error: e, stackTrace: stack);
    } finally {
      _isSyncing = false;
    }
  }

  /// Initiates purchase flow for a VIP subscription plan.
  Future<PurchaseResult> purchaseSubscription(PaymentProduct product) async {
    _log('🛒 [Purchase Flow] User tapped to buy: ${product.id} (${product.title}) - ${product.priceToman} Tomans');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _paymentService.subscribe(product.id);

      _log('📦 [Purchase Flow] Store response received:');
      _log('   ↳ isSuccess: ${result.isSuccess}');
      _log('   ↳ orderId: ${result.orderId}');
      _log('   ↳ purchaseToken: ${result.purchaseToken != null ? (result.purchaseToken!.length > 15 ? "${result.purchaseToken!.substring(0, 15)}..." : result.purchaseToken) : "null"}');
      _log('   ↳ errorMessage: ${result.errorMessage}');

      if (result.isSuccess) {
        final now = DateTime.now();
        final durationDays = product.durationDays;
        final newExpiry = durationDays != null
            ? now.add(Duration(days: durationDays))
            : null; // Lifetime

        _log('💾 [Local Save] Writing purchase to encrypted storage:');
        _log('   ↳ isVip: true');
        _log('   ↳ activePlanId: ${product.id}');
        _log('   ↳ expiryDate: $newExpiry (Duration: ${durationDays != null ? "$durationDays days" : "Lifetime"})');
        _log('   ↳ purchaseToken: ${result.purchaseToken}');

        await _storage.setIsVip(true);
        await _storage.setVipExpiryDate(newExpiry);
        await _storage.setActivePlanId(product.id);
        if (result.purchaseToken != null) {
          await _storage.setPurchaseToken(result.purchaseToken);
        }

        // Immediate verification read from storage
        final readVip = await _storage.getIsVip();
        final readExpiry = await _storage.getVipExpiryDate();
        final readPlan = await _storage.getActivePlanId();
        _log('🔍 [Local Verification Check] Re-read from secure storage: isVip=$readVip, plan=$readPlan, expiry=$readExpiry');
        if (readVip && readPlan == product.id) {
          _log('✅ [Local Verification Check] VERIFIED! Purchase safely saved and readable in encrypted storage.');
        } else {
          _log('⚠️ [Local Verification Check] MISMATCH detected between write and read in secure storage!');
        }

        state = state.copyWith(
          isVip: true,
          vipExpiryDate: newExpiry,
          activePlanId: product.id,
          isLoading: false,
        );
        _scheduleExactExpiryTimer(newExpiry);
        _log('🎉 [Purchase Complete] VIP state active for user. All features unlocked in application!');
      } else {
        _log('❌ [Purchase Failed/Cancelled] Error: ${result.errorMessage}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage,
        );
      }

      return result;
    } catch (e, stack) {
      _log('❌ [Purchase Exception] Unexpected error during purchase: $e', error: e, stackTrace: stack);
      final errorResult = PurchaseResult.error(
        'خطای غیرمنتظره در ارتباط با درگاه پرداخت: $e',
        productId: product.id,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorResult.errorMessage,
      );
      return errorResult;
    }
  }

  /// Restores previous active purchases.
  Future<bool> restorePurchases() async {
    _log('🔄 [Restore Flow] User requested to restore previous purchases...');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _paymentService.restorePurchases();

      _log('📥 [Restore Response] Received ${results.length} purchases from Cafe Bazaar:');
      for (final r in results) {
        _log('   ↳ Product: ${r.productId}, OrderId: ${r.orderId}, Token: ${r.purchaseToken}');
      }

      if (results.isNotEmpty) {
        final activeProduct = results.first;
        _log('✅ [Restore Success] Restoring subscription for product: ${activeProduct.productId}');
        await _storage.setIsVip(true);
        await _storage.setActivePlanId(activeProduct.productId);
        if (activeProduct.purchaseToken != null) {
          await _storage.setPurchaseToken(activeProduct.purchaseToken);
        }

        state = state.copyWith(
          isVip: true,
          activePlanId: activeProduct.productId,
          isLoading: false,
        );
        _log('🎉 [Restore Complete] Local storage updated and VIP access restored!');
        return true;
      }

      _log('ℹ️ [Restore Result] No active purchases found in Cafe Bazaar to restore.');
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e, stack) {
      _log('❌ [Restore Exception] Error restoring purchases: $e', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بازیابی اشتراک از کافه بازار: $e',
      );
      return false;
    }
  }

  /// Policy check: Can play the given reciter for the given surah?
  bool canPlayReciter({required String? reciterIdentifier, required int surahId}) {
    return AudioVipPolicy.canPlayReciter(
      reciterIdentifier: reciterIdentifier,
      surahId: surahId,
      isVip: state.hasVipAccess,
    );
  }

  /// Policy check: Can play Persian audio translation?
  bool canPlayAudioTranslation() {
    return AudioVipPolicy.canPlayAudioTranslation(isVip: state.hasVipAccess);
  }
}

/// Central controller provider for VIP subscriptions.
final vipSubscriptionControllerProvider =
    NotifierProvider<VipSubscriptionController, VipSubscriptionState>(
  VipSubscriptionController.new,
);

/// Convenience provider to easily check if current user holds VIP access.
final hasVipAccessProvider = Provider<bool>((ref) {
  if (VipSubscriptionState.isAllFeaturesFree) return true;
  return ref.watch(vipSubscriptionControllerProvider).hasVipAccess;
});
