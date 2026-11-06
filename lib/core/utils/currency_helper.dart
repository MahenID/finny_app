class CurrencyHelper {
  static String _currentCurrencyCode = 'IDR';

  static void setCurrency(String code) {
    if (code.trim().isNotEmpty) {
      _currentCurrencyCode = code.trim().toUpperCase();
    }
  }

  static String get currentCurrencyCode => _currentCurrencyCode;

  static String getSymbol([String? code]) {
    final currency = (code ?? _currentCurrencyCode).toUpperCase();
    switch (currency) {
      case 'USD':
        return '\$ ';
      case 'SGD':
        return 'S\$ ';
      case 'MYR':
        return 'RM ';
      case 'EUR':
        return '€ ';
      case 'IDR':
      default:
        return 'Rp ';
    }
  }

  /// Format angka integer atau double ke format mata uang standar.
  static String format(
    num amount, {
    bool showPrefix = true,
    bool showSign = false,
    String? currencyCode,
  }) {
    final bool isNegative = amount < 0;
    final int absoluteVal = amount.abs().toInt();

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

    final String formattedNumber =
        buffer.toString().split('').reversed.join('');

    String result = '';
    if (isNegative) {
      result = '-';
    } else if (showSign && amount > 0) {
      result = '+';
    }

    if (showPrefix) {
      final symbol = getSymbol(currencyCode);
      result += '$symbol$formattedNumber';
    } else {
      result += formattedNumber;
    }

    return result;
  }
}
