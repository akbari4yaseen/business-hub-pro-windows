String getCurrencyName(String currency) {
  const Map<String, String> currencyNames = {
    'USD': 'دالر',
    'TRY': 'لیره ترکیه',
    'SAR': 'ریال سعودی',
    'PKR': 'کلدار پاکستانی',
    'IRR': 'تومان',
    'INR': 'کلدار هندی',
    'GBP': 'پوند',
    'EUR': 'یورو',
    'CNY': 'ین چین',
    'CAD': 'دالر کانادایی',
    'AUD': 'دالر استرالیایی',
    'AFN': 'افغانی',
    'AED': 'درهم امارات',
    'MYR': 'رینگیت مالزی',
  };

  return currencyNames[currency] ?? currency;
}
