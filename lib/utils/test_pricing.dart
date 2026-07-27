/// Shared pricing rules for catalogue tests.
///
/// The offer is calculated per test so that catalogue cards, checkout totals,
/// and the database all agree on the amount the user pays.
abstract final class TestPricing {
  static const int discountPercent = 20;
  static const double _payableRate = 0.80;

  /// Applies the requested non-round ending after the percentage discount.
  ///
  /// Examples: 2000 -> 1999, 150 -> 149, and 1380 -> 1379.
  static int applyOfferEnding(int roundedDiscountedPrice) {
    final safePrice = roundedDiscountedPrice < 0 ? 0 : roundedDiscountedPrice;
    if (safePrice > 0 && safePrice % 5 == 0) return safePrice - 1;
    return safePrice;
  }

  /// Returns the payable whole-rupee price for one test.
  static double? sellingPrice(double? mrp) {
    if (mrp == null || !mrp.isFinite) return null;
    final safeMrp = mrp < 0 ? 0.0 : mrp;
    final discounted = (safeMrp * _payableRate).round();
    return applyOfferEnding(discounted).toDouble();
  }

  /// Formats rupees with Indian digit grouping.
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final safeAmount = amount.isFinite ? amount : 0;
    final negative = safeAmount < 0;
    final absolute = safeAmount.abs();
    final raw = absolute == absolute.roundToDouble()
        ? absolute.toStringAsFixed(0)
        : absolute.toStringAsFixed(2);
    final parts = raw.split('.');
    final groupedWhole = _groupIndianDigits(parts.first);
    final decimals = parts.length == 2 ? '.${parts.last}' : '';
    return '${negative ? '-' : ''}$symbol$groupedWhole$decimals';
  }

  static String _groupIndianDigits(String digits) {
    if (digits.length <= 3) return digits;

    final lastThree = digits.substring(digits.length - 3);
    var leading = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (leading.length > 2) {
      groups.insert(0, leading.substring(leading.length - 2));
      leading = leading.substring(0, leading.length - 2);
    }
    if (leading.isNotEmpty) groups.insert(0, leading);
    return '${groups.join(',')},$lastThree';
  }
}
