class CurrencyHelper {
  /// Format angka integer atau double ke format Rupiah standar Indonesia.
  /// Contoh: 1500000 -> "Rp 1.500.000"
  ///         -25000  -> "-Rp 25.000"
  static String format(num amount, {bool showPrefix = true, bool showSign = false}) {
    final bool isNegative = amount < 0;
    final int absoluteVal = amount.abs().toInt();

    // Format dengan separator titik setiap 3 digit
    final String strVal = absoluteVal.toString();
    final StringBuffer buffer = StringBuffer();

    int count = 0;
    for (int i = strVal.length - 1; i >= 0; i--) {
      buffer.write(strVal[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }

    final String formattedNumber = buffer.toString().split('').reversed.join('');

    String result = '';
    if (isNegative) {
      result = '-';
    } else if (showSign && amount > 0) {
      result = '+';
    }

    if (showPrefix) {
      result += 'Rp $formattedNumber';
    } else {
      result += formattedNumber;
    }

    return result;
  }
}
