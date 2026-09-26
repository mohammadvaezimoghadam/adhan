import '../../../../core/services/payment/models/payment_product.dart';

/// State representation of the user's VIP membership and active products.
class VipSubscriptionState {
  /// Global toggle: When true, all features across the app (reciters, translations, playback modes)
  /// are 100% free for all users without requiring a paid subscription.
  static bool isAllFeaturesFree = true;

  final bool isVip;
  final DateTime? vipExpiryDate;
  final String? activePlanId;
  final List<PaymentProduct> availableProducts;
  final bool isLoading;
  final String? errorMessage;

  const VipSubscriptionState({
    this.isVip = false,
    this.vipExpiryDate,
    this.activePlanId,
    this.availableProducts = PaymentProduct.allSubscriptions,
    this.isLoading = false,
    this.errorMessage,
  });

  /// True if the user currently holds an active paid VIP subscription or lifetime access.
  bool get hasVipAccess {
    if (isAllFeaturesFree) return true;
    if (!isVip) return false;
    if (vipExpiryDate == null) return true; // Lifetime VIP
    return DateTime.now().isBefore(vipExpiryDate!);
  }

  /// Remaining days of VIP subscription.
  int get remainingDays {
    if (isVip && vipExpiryDate != null) {
      final diff = vipExpiryDate!.difference(DateTime.now()).inDays;
      return diff >= 0 ? diff : 0;
    }
    return 0;
  }

  VipSubscriptionState copyWith({
    bool? isVip,
    DateTime? vipExpiryDate,
    String? activePlanId,
    List<PaymentProduct>? availableProducts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VipSubscriptionState(
      isVip: isVip ?? this.isVip,
      vipExpiryDate: vipExpiryDate ?? this.vipExpiryDate,
      activePlanId: activePlanId ?? this.activePlanId,
      availableProducts: availableProducts ?? this.availableProducts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
