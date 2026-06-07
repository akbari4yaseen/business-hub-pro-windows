// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'بیزنس‌هاب';

  @override
  String get languageEnglish => 'انگلیسی';

  @override
  String get languageFarsi => 'فارسی';

  @override
  String get languagePashto => 'پشتو';

  @override
  String get home => 'صفحه اصلی';

  @override
  String get journal => 'روزنامچه';

  @override
  String get accounts => 'حساب‌ها';

  @override
  String get exchange => 'تبادله اسعار';

  @override
  String get accountsPrint => 'حساب ها';

  @override
  String get reports => 'گزارشات';

  @override
  String get inventory => 'گدام';

  @override
  String get password => 'رمزعبور';

  @override
  String get login => 'ورود';

  @override
  String get invalidPassword => 'رمزعبور اشتباه است';

  @override
  String get addAccount => 'حساب جدید';

  @override
  String get addJournal => 'روزنامچه جدید';

  @override
  String get editJournal => 'ویرایش روزنامچه';

  @override
  String get accountName => 'نام حساب';

  @override
  String get accountType => 'نوع حساب';

  @override
  String get customer => 'مشتری';

  @override
  String get employee => 'کارمند';

  @override
  String get supplier => 'فراهم‌کننده';

  @override
  String get exchanger => 'صراف';

  @override
  String get system => 'سیستم';

  @override
  String get phone => 'شماره تماس';

  @override
  String get call => 'تماس';

  @override
  String get callError => 'امکان برقراری تماس وجود ندارد';

  @override
  String get address => 'آدرس';

  @override
  String get save => 'ثبت';

  @override
  String get nameRequired => 'نام الزامی است!';

  @override
  String get treasure => 'خزانه';

  @override
  String get noTreasure => 'بدون خزانه';

  @override
  String get asset => 'سرمایه';

  @override
  String get profit => 'مفاد';

  @override
  String get loss => 'ضرر';

  @override
  String get expenses => 'مصارف';

  @override
  String get activeAccounts => 'حساب‌های فعال';

  @override
  String get deactivatedAccounts => 'حساب‌های غیرفعال';

  @override
  String get transactions => 'معاملات حساب';

  @override
  String get editAccount => 'ویرایش حساب';

  @override
  String get deactivateAccount => 'غیرفعال کردن حساب';

  @override
  String get reactivateAccount => 'فعال‌سازی مجدد حساب';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get confirmDelete => 'تأیید حذف';

  @override
  String get confirmDeactivate => 'تأیید غیرفعالسازی';

  @override
  String get confirmReactivate => 'تأیید فعالسازی مجدد';

  @override
  String get cancel => 'لغو';

  @override
  String get delete => 'حذف';

  @override
  String get confirm => 'تایید';

  @override
  String get deactivate => 'غیرفعال کردن';

  @override
  String get reactivate => 'فعال‌سازی';

  @override
  String get shareBalance => 'اشتراک گذاری بیلانس';

  @override
  String get sendBalance => 'ارسال بیلانس';

  @override
  String get invalidPhone => 'شماره تماس نادرست است';

  @override
  String get saveError => 'خطا در ثبت اطلاعات';

  @override
  String get existsAccountError => 'حسابی با این نام از قبل وجود دارد';

  @override
  String get selectAccount => 'انتخاب حساب';

  @override
  String get amount => 'مبلغ';

  @override
  String get description => 'توضیحات';

  @override
  String get selectTrack => 'انتخاب درک';

  @override
  String get credit => 'آوردگی';

  @override
  String get debit => 'بردگی';

  @override
  String get credited => 'آوردگی';

  @override
  String get debited => 'بردگی';

  @override
  String get track => 'درک';

  @override
  String get typeToSearchTrack => 'برای جستجوی درک تایپ کنید';

  @override
  String get pleaseSelectTrack => 'لطفا یک درک را انتخاب کنید';

  @override
  String get pleaseSelectAccount => 'لطفا یک حساب را انتخاب کنید';

  @override
  String get amountRequired => 'مبلغ لازم است';

  @override
  String get search => 'جستجو';

  @override
  String get purchases => 'خریدها';

  @override
  String get searchJournal => 'جستجوی روزنامچه...';

  @override
  String deleteAccountConfirm(Object accountName) {
    return 'آیا مطمئن هستید که می‌خواهید $accountName را حذف کنید؟';
  }

  @override
  String deactivateAccountConfirm(Object accountName) {
    return 'آیا مطمئن هستید که می‌خواهید حساب $accountName را غیرفعال کنید؟';
  }

  @override
  String reactivateAccountConfirm(Object accountName) {
    return 'آیا می‌خواهید حساب $accountName را دوباره فعال کنید؟';
  }

  @override
  String get noAccountsAvailable => 'حسابی موجود نیست';

  @override
  String get noMoreAccounts => 'حساب بیشتری وجود ندارد';

  @override
  String get searchAccount => 'جستجوی حساب‌ها...';

  @override
  String get all => 'همه';

  @override
  String get changePassword => 'تغییر گذرواژه';

  @override
  String get currentPassword => 'گذرواژه فعلی';

  @override
  String get newPassword => 'گذرواژه جدید';

  @override
  String get confirmPassword => 'تأیید گذرواژه';

  @override
  String get passwordUpdated => 'گذرواژه با موفقیت تغییر یافت';

  @override
  String get incorrectCurrentPassword => 'گذرواژه فعلی اشتباه است';

  @override
  String get fieldRequired => 'این فیلد الزامی است';

  @override
  String get passwordTooShort => 'حداقل باید ۶ کاراکتر باشد';

  @override
  String get passwordsDoNotMatch => 'گذرواژه‌ها مطابقت ندارند';

  @override
  String get loginHeader => 'ورود به سیستم';

  @override
  String get passwordLabel => 'رمز عبور';

  @override
  String get loginButton => 'وارد شدن';

  @override
  String get forgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get enterPassword => 'لطفا رمز عبور خود را وارد کنید.';

  @override
  String get wrongPassword => 'رمز عبور اشتباه است.';

  @override
  String get appName => 'بیزنس‌هاب';

  @override
  String get settings => 'تنظیمات';

  @override
  String get help => 'راهنمایی';

  @override
  String get about => 'درباره';

  @override
  String get logout => 'خروج';

  @override
  String get darkMode => 'حالت تیره';

  @override
  String get backupTitle => 'پشتیبان‌گیری دیتابیس';

  @override
  String get backup => 'پشتیبان‌گیری';

  @override
  String get restore => 'بازیابی';

  @override
  String get exportCanceledNoDirectory =>
      'عملیات لغو شد. هیچ پوشه‌ای انتخاب نشد.';

  @override
  String databaseExportedSuccessfully(Object path) {
    return 'دیتابیس با موفقیت صادر شد به:\n$path';
  }

  @override
  String get databaseFileNotFoundOrExportFailed =>
      'فایل دیتابیس یافت نشد یا عملیات صادر کردن ناموفق بود!';

  @override
  String errorExportingDatabase(Object error) {
    return 'خطا در صادر کردن دیتابیس: $error';
  }

  @override
  String get restoreCanceledNoFile =>
      'عملیات بازیابی لغو شد. هیچ فایلی انتخاب نشد.';

  @override
  String get databaseRestoredSuccessfully =>
      'دیتابیس با موفقیت بازیابی شد! لطفاً برنامه را مجدداً راه‌اندازی کنید.';

  @override
  String get restoreFailedFileNotFound =>
      'بازیابی ناموفق بود! فایل یافت نشد یا خطا رخ داد.';

  @override
  String errorRestoringDatabase(Object error) {
    return 'خطا در بازیابی دیتابیس: $error';
  }

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get companyInfo => 'اطلاعات شرکت';

  @override
  String themeMode(Object mode) {
    return 'حالت $mode';
  }

  @override
  String get dark => 'تاریک';

  @override
  String get light => 'روشن';

  @override
  String get filters => 'فیلترها';

  @override
  String get filter => 'فیلتر';

  @override
  String get maxBalance => 'حداکثر بیلانس';

  @override
  String get positiveNegativeBalances => 'بیلانس مثبت / منفی';

  @override
  String get showPositiveBalances => 'نمایش بیلانس مثبت';

  @override
  String get showNegativeBalances => 'نمایش بیلانس منفی';

  @override
  String get defaultCurrency => 'واحدل پول پیش فرض';

  @override
  String get defaultTransactionType => 'نوع معامله پیش فرض';

  @override
  String get defaultTrack => 'درک پیش فرض';

  @override
  String get appLanguage => 'زبان برنامه';

  @override
  String get businessName => 'نام شرکت';

  @override
  String get whatsApp => 'واتساپ';

  @override
  String get email => 'ایمیل';

  @override
  String get saveChanges => 'ثبت تغییرات';

  @override
  String get companyInfoUpdated => 'معلومات شرکت بروز رسانی شد';

  @override
  String get companyInfoUpdateError => 'خطا در بروزرسانی اطلاعات شرکت';

  @override
  String get invalidEmail => 'ایمیل معتبر نیست';

  @override
  String get confirmDeleteJournal =>
      'آیا مطمئن هستید که می‌خواهید این معامله را حذف کنید؟ این عملیات قابل بازگشت نیست.';

  @override
  String get journalDetails => 'جزئیات معامله';

  @override
  String get noDescription => 'بدون توضیحات';

  @override
  String get date => 'تاریخ';

  @override
  String get transactionType => 'نوع معامله';

  @override
  String get account => 'حساب';

  @override
  String get close => 'بستن';

  @override
  String get details => 'جزئیات';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get edit => 'ویرایش';

  @override
  String get printDisabled => 'چاپ (غیرفعال)';

  @override
  String get print => 'چاپ';

  @override
  String get noJournalEntries => 'روزنامچه خالی است.';

  @override
  String get clear => 'پاک کردن';

  @override
  String get reset => 'باز نشاندن';

  @override
  String get accountFilters => 'فیلترهای حساب';

  @override
  String get balanceRange => 'محدوده بیلانس';

  @override
  String get min => 'حداقل';

  @override
  String get max => 'حداکثر';

  @override
  String get balanceType => 'نوع بیلانس';

  @override
  String get positive => 'مثبت';

  @override
  String get negative => 'منفی';

  @override
  String get applyFilters => 'تطبیق فیلتر';

  @override
  String get maxAmount => 'مبلغ پایین';

  @override
  String get minAmount => 'مبلغ بالا';

  @override
  String get apply => 'تطبیق';

  @override
  String get balance => 'بیلانس';

  @override
  String get selectDate => 'انتخاب تاریخ';

  @override
  String get currency => 'واحد پول';

  @override
  String get income => 'عاید';

  @override
  String get expense => 'مصرف';

  @override
  String get bank => 'بانک';

  @override
  String get owner => 'مالک';

  @override
  String get company => 'شرکت';

  @override
  String get errorDeletingJournal =>
      'خطا در حذف روزنامچه. لطفاً دوباره تلاش کنید.';

  @override
  String get errorLoadingJournal =>
      'خطا در بارگذاری روزنامچه. لطفاً دوباره تلاش کنید.';

  @override
  String get storagePermissionRequired => 'اجازه دسترسی به حافظه لازم است';

  @override
  String shareMessageHeader(Object name) {
    return '📢 محترم *$name*\n\nدر ادامه، خلاصه‌ای کامل از بیلانس حساب شما در تمام ارزهای ثبت‌شده آمده است. این اطلاعات براساس آخرین معاملات ثبت‌شده در سیستم می‌باشد.\n\nلطفاً این بیلانس‌ها را با دقت بررسی نمایید تا از هرگونه مغایرت جلوگیری شود.\n\n*بیلانس:*';
  }

  @override
  String shareMessageTimestamp(Object date) {
    return '*زمان:* $date';
  }

  @override
  String shareMessageFooter(Object appName) {
    return '---------------\n$appName';
  }

  @override
  String get shareMessagePaymentReminder =>
      '💡 *لطفاً باقیمانده حساب را پرداخت کنید.*';

  @override
  String get profile => 'پروفایل';

  @override
  String get notifications => 'اعلانات';

  @override
  String get statsLoadError => 'خطا در بارگذاری آمار حساب‌ها';

  @override
  String get allAccounts => 'همه';

  @override
  String get activeAccountsShort => 'فعال';

  @override
  String get deactivatedAccountsShort => 'غیرفعال';

  @override
  String get newTransaction => 'معامله جدید';

  @override
  String get recentTransactions => 'معاملات اخیر';

  @override
  String get noRecentTransactions => 'معامله اخیر وجود ندارد';

  @override
  String get noTransactionsFound => 'معامله‌ای وجود ندارد';

  @override
  String get noExchangesFound => 'تبادله اسعار یافت نشد';

  @override
  String get transactionEditError => 'خطا در ویرایش روزنامچه';

  @override
  String get transactionNotFound => 'معامله‌ای وجود ندارد';

  @override
  String get transactionDeleteError => 'خطا در حذف معامله';

  @override
  String get onlineBackupSuccess => 'پشتیبان‌گیری آنلاین با موفقیت انجام شد';

  @override
  String get onlineBackupFailed => 'پشتیبان‌گیری آنلاین ناموفق بود';

  @override
  String get localBackupSuccess => 'پشتیبان‌گیری آفلاین با موفقیت انجام شد';

  @override
  String get localBackupFailed => 'پشتیبان‌گیری آفلاین ناموفق بود';

  @override
  String get confirmRestore => 'تأیید بازیابی';

  @override
  String get restoreOverwriteWarning =>
      'این عمل داده‌های موجود را بازنویسی می‌کند. ادامه می‌دهید؟';

  @override
  String get restoreSuccess => 'بازیابی دیتابیس با موفقیت انجام شد';

  @override
  String get restoreFailed => 'بازیابی دیتابیس ناموفق بود';

  @override
  String get databaseSettings => 'تنظیمات دیتابیس';

  @override
  String get baseUnit => 'واحد پایه';

  @override
  String get lastOnlineBackup => 'آخرین پشتیبان‌گیری آنلاین';

  @override
  String get lastOfflineBackup => 'آخرین پشتیبان‌گیری آفلاین';

  @override
  String get backupOnline => 'پشتیبان‌گیری آنلاین';

  @override
  String get backupLocal => 'پشتیبان‌گیری آفلاین';

  @override
  String get restoreDatabase => 'بازیابی دیتابیس';

  @override
  String get reminders => 'یادآور‌ها';

  @override
  String get reminder => 'یادآور';

  @override
  String get systemAccount => 'حساب‌های سیستم';

  @override
  String get error => 'خطا';

  @override
  String get noSystemAccountsFound => 'هیچ حساب سیستم یافت نشد.';

  @override
  String get currencies => 'واحد‌های پولی';

  @override
  String get current => 'فعلی';

  @override
  String get noDataAvailable => 'اطلاعات وجود ندارد';

  @override
  String get accountReports => 'گزارش حساب‌ها';

  @override
  String get accountReportsDesc => 'بیلانس‌ها و موارد دیگر';

  @override
  String get dailyBalancesDesc => 'نمودار خطی بیلانس روزانه حساب‌ها';

  @override
  String get systemAccountReports => 'گزارش حساب‌های سیستم';

  @override
  String get systemAccountReportsDesc => 'لیست حساب‌های سیستم و بیلانس‌ها';

  @override
  String get moreVisualizations => 'بصری‌سازی‌های بیشتر';

  @override
  String get moreVisualizationsDesc =>
      'نمودارها و تحلیل‌های آینده اینجا نمایش داده می‌شود';

  @override
  String get accountLabel => 'حساب';

  @override
  String get currentLabel => 'فعلی';

  @override
  String get periodWeek => '۱هفته';

  @override
  String get periodMonth => '۱ماه';

  @override
  String get period3Months => '۳ماه';

  @override
  String get period6Months => '۶ماه';

  @override
  String get periodYear => '۱سال';

  @override
  String get period3Years => '۳سال';

  @override
  String get periodAll => 'همه';

  @override
  String get metricCurrentBalance => 'بیلانس فعلی';

  @override
  String get metricChange => 'تغییرات';

  @override
  String get dailyBalances => 'بیلانس روزانه';

  @override
  String get accountBalances => 'بیلانس حساب‌ها';

  @override
  String get accountsByType => 'حساب‌ها بر اساس نوع';

  @override
  String balanceLabel(Object currency) {
    return 'بیلانس ($currency)';
  }

  @override
  String totalCount(Object count) {
    return 'تعداد: $count';
  }

  @override
  String printed(Object date) {
    return 'چاپ شده: $date';
  }

  @override
  String pageOf(Object page, Object total) {
    return 'صفحه $page از $total';
  }

  @override
  String get number => 'شماره';

  @override
  String get remindersTitle => 'یادآورها';

  @override
  String get deleteReminderTitle => 'حذف یادآور';

  @override
  String get deleteReminderConfirmation =>
      'آیا مطمئن هستید که می‌خواهید این یادآور را حذف کنید؟';

  @override
  String get noRemindersYet => 'هنوز یادآوری وجود ندارد!';

  @override
  String get newReminderTitle => 'یادآور جدید';

  @override
  String get editReminderTitle => 'ویرایش یادآور';

  @override
  String get titleLabel => 'عنوان';

  @override
  String get descriptionLabel => 'توضیحات';

  @override
  String get dateTimeLabel => 'تاریخ و زمان';

  @override
  String get repeatLabel => 'تکرار';

  @override
  String get intervalLabel => 'فاصله';

  @override
  String get daily => 'روزانه';

  @override
  String get weekly => 'هفتگی';

  @override
  String get defaultReminder => 'زمان یادآوری شما فرا رسیده است!';

  @override
  String get repeats => 'تکرار می‌شود';

  @override
  String get titleEmptyError => 'لطفاً عنوان را وارد کنید';

  @override
  String get pickDateTimeError => 'لطفاً تاریخ و زمان را انتخاب کنید';

  @override
  String get notificationsTitle => 'اعلانات';

  @override
  String get markAllReadTooltip => 'علامت‌گذاری همه به‌عنوان خوانده‌شده';

  @override
  String get clearAllTooltip => 'حذف همه';

  @override
  String get clearAllNotificationsTitle => 'حذف همهٔ اعلانات';

  @override
  String get notificationDeleted => 'اعلان حذف شد';

  @override
  String get clearAllNotificationsContent =>
      'آیا مطمئن هستید که می‌خواهید همهٔ اعلانات را حذف کنید؟';

  @override
  String get noNotifications => 'هیچ اعلانی وجود ندارد';

  @override
  String get undo => 'لغو عمل';

  @override
  String get loading => 'در حال بارگیری...';

  @override
  String get useFingerprint => 'استفاده از اثر انگشت';

  @override
  String get biometricReason =>
      'لطفاً برای دسترسی به بیزنیزهاب احراز هویت کنید';

  @override
  String get biometricError => 'احراز هویت بیومتریک ناموفق بود';

  @override
  String get backupCardFriendlyMessage =>
      'اطلاعات خود را ایمن نگه دارید! فراموش نکنید که به‌طور منظم پشتیبان‌گیری کنید.';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
      one: 'یک روز پیش',
      zero: 'امروز',
    );
    return '$_temp0';
  }

  @override
  String get online => 'آنلاین';

  @override
  String get offline => 'آفلاین';

  @override
  String get enterPasswordError => 'رمز عبور را وارد کنید';

  @override
  String get authTitle => 'احراز هویت';

  @override
  String get biometricFailed => 'احراز هویت بیومتریک ناموفق بود';

  @override
  String get deleteAccountAuthMessage => 'برای حذف حساب احراز هویت لازم است';

  @override
  String get deleteJournalAuthMessage =>
      'برای حذف این روزنامچه احراز هویت لازم است';

  @override
  String get confirmDeleteTransaction =>
      'آیا مطمئن هستید که می‌خواهید این معامله را حذف کنید؟ این عملیات قابل بازگشت نیست.';

  @override
  String get journalSaved => 'روزنامچه ثبت شد';

  @override
  String get errorSavingJournal => 'خطا در ثبت روزنامچه';

  @override
  String get printSettings => 'تنظیمات چاپ';

  @override
  String get preparingPrint => 'در حال آماده‌سازی چاپ...';

  @override
  String get startDate => 'تاریخ شروع';

  @override
  String get endDate => 'تاریخ ختم';

  @override
  String shareMessage(Object accountName, Object action, Object amount,
      Object currency, Object date, Object description, Object footer) {
    return 'محترم $accountName،\n\nحساب شما در تاریخ $date به مبلغ $amount $currency $action شده است.\n\nتوضیحات بیشتر: $description\n\n$footer';
  }

  @override
  String get onlineBackupOverdueTitle => 'پشتیبان‌گیری آنلاین دیر شده';

  @override
  String get onlineBackupOverdueMessage =>
      'آخرین پشتیبان‌گیری آنلاین شما بیش از ۷ روز پیش بوده است. لطفاً اطلاعات خود را به صورت آنلاین پشتیبان‌گیری کنید.';

  @override
  String get offlineBackupOverdueTitle => 'پشتیبان‌گیری آفلاین دیر شده';

  @override
  String get offlineBackupOverdueMessage =>
      'آخرین پشتیبان‌گیری آفلاین شما بیش از ۷ روز پیش بوده است. لطفاً اطلاعات خود را محلی/آفلاین پشتیبان‌گیری کنید.';

  @override
  String accountInactiveTitle(Object name) {
    return 'حساب «$name» بدون فعالیت است';
  }

  @override
  String accountInactiveMessage(Object days, Object name) {
    return 'حساب «$name» در $days روز گذشته هیچ معامله‌ای نداشته است.';
  }

  @override
  String get inactivityDays => 'تعداد روزهای بدون معامله بودن حساب';

  @override
  String get periodicReports => 'گزارش‌های دوره‌ای';

  @override
  String get periodicReportsDesc => 'نمایش بردگی‌ و آوردگی‌ها در دوره زمانی';

  @override
  String get today => 'امروز';

  @override
  String get yesterday => 'دیروز';

  @override
  String get last7Days => '۷ روز گذشته';

  @override
  String get last14Days => '۱۴ روز گذشته';

  @override
  String get lastMonth => 'ماه گذشته';

  @override
  String get last3Months => '۳ ماه گذشته';

  @override
  String get last6Months => '۶ ماه گذشته';

  @override
  String get lastYear => 'سال گذشته';

  @override
  String get customRange => 'دوره دلخواه';

  @override
  String get period => 'دوره';

  @override
  String get generateReport => 'ایجاد گزارش';

  @override
  String get totalCredit => 'کل آوردگی';

  @override
  String get totalDebit => 'کل بردگی';

  @override
  String get pleaseSelectAllFilters => 'لطفا تمام فیلترها را انتخاب کنید';

  @override
  String get pleaseSelectDateRange => 'لطفا دوره زمانی را انتخاب کنید';

  @override
  String get product => 'جنس';

  @override
  String get quantity => 'تعداد';

  @override
  String get unitPrice => 'فی';

  @override
  String get total => 'مجموع';

  @override
  String get unknownProduct => 'جنس ناشناخته';

  @override
  String get invoice => 'فاکتور';

  @override
  String get invoiceDate => 'تاریخ فاکتور';

  @override
  String get dueDate => 'تاریخ رسید';

  @override
  String get subtotal => 'جمع کل';

  @override
  String get paidAmount => 'مبلغ پرداخت شده';

  @override
  String get balanceDue => 'باقی مانده';

  @override
  String get notes => 'یادداشت‌ها';

  @override
  String get note => 'یادداشت';

  @override
  String get soldGoodsNotReturnable => 'جنس فروخته شده پس گرفته نمی شود';

  @override
  String get sells => 'فروشات';

  @override
  String get inventoryManagement => 'مدیریت گدام';

  @override
  String get currentStock => 'موجودی فعلی';

  @override
  String get products => 'اجناس';

  @override
  String get warehouses => 'گدام‌ها';

  @override
  String get stockMovements => 'جابجایی موجودی';

  @override
  String get invoices => 'فاکتورها';

  @override
  String get allInvoices => 'همه فاکتورها';

  @override
  String get overdue => 'سررسید';

  @override
  String get createInvoice => 'ایجاد فاکتور';

  @override
  String failedRecordPayment(Object error) {
    return 'خطا در ثبت پرداخت: $error';
  }

  @override
  String failedFinalizeInvoice(Object error) {
    return 'خطا در نهایی‌سازی فاکتور: $error';
  }

  @override
  String get confirmFinalizeInvoice => 'تأیید نهایی‌سازی فاکتور';

  @override
  String get finalizeInvoiceConfirmation =>
      'آیا مطمئن هستید که می‌خواهید این فاکتور را نهایی کنید؟ این عمل قابل بازگشت نیست.';

  @override
  String get noInvoices => 'هیچ فاکتوری پیدا نشد';

  @override
  String get noOverdueInvoices => 'هیچ فاکتور سررسید گذشته‌ای وجود ندارد';

  @override
  String customerInvoice(Object name) {
    return 'مشتری: $name';
  }

  @override
  String dateInvoice(Object date) {
    return 'تاریخ: $date';
  }

  @override
  String dueInvoice(Object date) {
    return 'سررسید: $date';
  }

  @override
  String totalInvoice(Object amount) {
    return 'جمله: $amount';
  }

  @override
  String paidInvoice(Object amount) {
    return 'پرداخت شده: $amount';
  }

  @override
  String balanceInvoice(Object amount) {
    return 'باقیمانده: $amount';
  }

  @override
  String overdueByInvoice(Object days) {
    return '$days روز گذشته از سررسید';
  }

  @override
  String get finalize => 'نهایی کردن';

  @override
  String get recordPayment => 'ثبت پرداخت';

  @override
  String get editInvoice => 'ویرایش فاکتور';

  @override
  String get deleteInvoice => 'حذف فاکتور';

  @override
  String get printInvoice => 'چاپ فاکتور';

  @override
  String get items => 'قلم';

  @override
  String get deleteInvoiceConfirmation =>
      'آیا از حذف این فاکتور مطمئن هستید؟ این عملیات قابل بازگشت نیست.';

  @override
  String get invoiceDeleted => 'فاکتور با موفقیت حذف شد';

  @override
  String get errorDeletingInvoice => 'خطا در حذف فاکتور';

  @override
  String get invoiceDetails => 'جزئیات فاکتور';

  @override
  String get invoiceLabel => 'فاکتور';

  @override
  String get outstandingBalance => 'مانده بدهی';

  @override
  String get paymentAmount => 'مبلغ پرداخت';

  @override
  String get pleaseEnterPaymentAmount => 'لطفاً مبلغ پرداخت را وارد کنید';

  @override
  String get enterValidAmount => 'لطفاً یک مبلغ معتبر وارد کنید';

  @override
  String get amountGreaterThanZero => 'مبلغ باید بیشتر از صفر باشد';

  @override
  String get amountExceedsBalance => 'مبلغ نمی‌تواند بیشتر از مانده بدهی باشد';

  @override
  String get invoiceNumber => 'شماره فاکتور';

  @override
  String get invoiceNumberRequired => 'شماره فاکتور الزامی است';

  @override
  String get customerName => 'نام مشتری';

  @override
  String get customerNameRequired => 'نام مشتری الزامی است';

  @override
  String get invalidAmount => 'لطفاً یک مبلغ معتبر وارد کنید (بزرگتر از ۰)';

  @override
  String get invoiceSaved => 'فاکتور با موفقیت ذخیره شد';

  @override
  String get notSet => 'تنظیم نشده';

  @override
  String get addItem => 'افزودن قلم';

  @override
  String get noItemsAdded =>
      'هنوز هیچ قلمی اضافه نشده است. برای شروع روی \"افزودن قلم\" کلیک کنید.';

  @override
  String get additionalInformation => 'اطلاعات اضافی';

  @override
  String get noCustomersFound =>
      'هیچ مشتری‌ای یافت نشد. لطفاً ابتدا یک حساب مشتری اضافه کنید.';

  @override
  String get customerAccount => 'حساب مشتری';

  @override
  String get pleaseSelectProductForAllItems =>
      'لطفاً برای تمام اقلام یک جنس انتخاب کنید';

  @override
  String get quantityMustBeGreaterThanZero =>
      'تعداد باید برای تمام اقلام بیشتر از صفر باشد';

  @override
  String get updating => 'در حال ویرایش';

  @override
  String get creating => 'در حال ایجاد';

  @override
  String get noProductsAvailable =>
      'هیچ جنسی موجود نیست. ابتدا به موجودی جنس اضافه کنید.';

  @override
  String warningNoStockFor(Object product) {
    return 'هشدار: موجودی برای $product موجود نیست';
  }

  @override
  String get availableStock => 'موجودی';

  @override
  String get noStockAvailable => 'موجودی وجود ندارد';

  @override
  String get descriptionOptional => 'توضیحات (اختیاری)';

  @override
  String get remove => 'حذف';

  @override
  String get invalidPrice => 'قیمت نامعتبر است';

  @override
  String get required => 'ضروری';

  @override
  String get notEnoughStock => 'موجودی کافی نیست';

  @override
  String get invalidQuantity => 'تعداد نامعتبر است';

  @override
  String get stock => 'موجودی';

  @override
  String get pleaseSelectProduct => 'لطفاً یک جنس  را انتخاب کنید';

  @override
  String get invoiceStatusDraft => 'پیش‌نویس';

  @override
  String get invoiceStatusFinalized => 'نهایی شده';

  @override
  String get invoiceStatusPartiallyPaid => 'بخشی پرداخت شده';

  @override
  String get invoiceStatusPaid => 'پرداخت شده';

  @override
  String get invoiceStatusCancelled => 'لغو شده';

  @override
  String get preSale => 'پیش‌فروش';

  @override
  String get isPreSale => 'پیش‌فروش است';

  @override
  String get preSaleDescription =>
      'فاکتورهای پیش‌فروش امکان فروش محصولات بدون بررسی موجودی را فراهم می‌کنند';

  @override
  String get preSaleWarning => 'حالت پیش‌فروش: موجودی بررسی نخواهد شد';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get activeFilters => 'فیلترهای فعال';

  @override
  String get clearAll => 'پاک کردن همه';

  @override
  String get lowStockAlerts => 'هشدارهای موجودی کم';

  @override
  String get expiringProducts => 'اجناس در حال انقضا';

  @override
  String get noItemsFound => 'موردی یافت نشد';

  @override
  String get searchProducts => 'جستجوی اجناس...';

  @override
  String get warehouse => 'گدام';

  @override
  String get allWarehouses => 'همه گدام‌ها';

  @override
  String get category => 'کتگوری';

  @override
  String get allCategories => 'همه کتگوری‌ها';

  @override
  String get location => 'مکان';

  @override
  String get expires => 'انقضا';

  @override
  String get sku => 'کد جنس';

  @override
  String get unit => 'واحد';

  @override
  String get minimumStock => 'حداقل موجودی';

  @override
  String get maximumStock => 'حداکثر موجودی';

  @override
  String get expiryDate => 'تاریخ انقضا';

  @override
  String get lastMovement => 'آخرین جابجایی';

  @override
  String get moveStock => 'جابجایی موجودی';

  @override
  String get adjustQuantity => 'تنظیم مقدار';

  @override
  String get viewHistory => 'مشاهده تاریخچه';

  @override
  String get refreshProducts => 'بروزرسانی اجناس';

  @override
  String get categories => 'کتگوری‌ها';

  @override
  String get units => 'واحدها';

  @override
  String get showInactive => 'نمایش غیرفعال‌ها';

  @override
  String get noProductsFound => 'جنسی پیدا نشد';

  @override
  String get changeSearchCriteria => 'معیارهای جستجو را تغییر دهید';

  @override
  String get addProduct => 'افزودن جنس';

  @override
  String get editProduct => 'ویرایش جنس';

  @override
  String get activate => 'فعال‌سازی';

  @override
  String get deleteProduct => 'حذف جنس';

  @override
  String deleteConfirm(Object productName) {
    return 'آیا مطمئن هستید که می‌خواهید $productName را حذف کنید؟';
  }

  @override
  String get deleteSuccess => 'جنس با موفقیت حذف شد';

  @override
  String get activatedSuccess => 'جنس با موفقیت فعال شد';

  @override
  String get deactivatedSuccess => 'جنس با موفقیت غیرفعال شد';

  @override
  String get inactive => 'غیرفعال';

  @override
  String get barcode => 'بارکد';

  @override
  String get basicInfo => 'اطلاعات پایه';

  @override
  String get stockSettings => 'تنظیمات موجودی';

  @override
  String get minStock => 'حداقل موجودی';

  @override
  String get maxStock => 'حداکثر موجودی';

  @override
  String get reorderPoint => 'نقطه سفارش‌گذاری';

  @override
  String get search_warehouses => 'جستجوی گدام‌ها';

  @override
  String get show_empty => 'نمایش خالی‌ها';

  @override
  String get refresh_warehouses => 'بارگذاری مجدد گدامها';

  @override
  String get no_warehouses_found => 'هیچ گدامی یافت نشد';

  @override
  String get clear_filters => 'حذف فیلترها';

  @override
  String get edit_warehouse => 'ویرایش گدام';

  @override
  String get delete_warehouse => 'حذف گدام';

  @override
  String delete_warehouse_confirm(Object name) {
    return 'آیا مطمئن هستید که می‌خواهید گدام \"$name\" را حذف کنید؟';
  }

  @override
  String get warehouse_deleted => 'گدام با موفقیت حذف شد';

  @override
  String get no_items_in_warehouse => 'هیچ قلمی در این گدام وجود ندارد';

  @override
  String get minimum => 'حداقل';

  @override
  String get notAvailable => 'ناموجود';

  @override
  String get noMovementsFound => 'هیچ جابجایی‌ای پیدا نشد';

  @override
  String get movementType => 'نوع جابجایی';

  @override
  String get movementType_purchase => 'خرید';

  @override
  String get purchase => 'خرید';

  @override
  String get movementType_sale => 'فروش';

  @override
  String get allTypes => 'همه نوع‌ها';

  @override
  String get selectDateRange => 'بازه زمانی را انتخاب کنید';

  @override
  String get from => 'از';

  @override
  String get to => 'به';

  @override
  String get reference => 'ارجاع';

  @override
  String get movementDetails => 'جزئیات جابجایی';

  @override
  String get type => 'نوع';

  @override
  String get source => 'مبدا';

  @override
  String get destination => 'مقصد';

  @override
  String get createdAt => 'تاریخ ایجاد';

  @override
  String get productActivated => 'جنس با موفقیت فعال شد';

  @override
  String get productDeactivated => 'جنس با موفقیت غیرفعال شد';

  @override
  String get productDeleted => 'جنس با موفقیت حذف شد';

  @override
  String confirmDeleteProduct(Object productName) {
    return 'آیا مطمئن هستید که می‌خواهید $productName را حذف کنید؟';
  }

  @override
  String get movementType_stockIn => 'ورود به انبار';

  @override
  String get movementType_stockOut => 'خروج از انبار';

  @override
  String get movementType_transfer => 'انتقال';

  @override
  String get movementType_adjustment => 'اصلاح موجودی';

  @override
  String get add_unit => 'افزودن واحد';

  @override
  String get edit_unit => 'ویرایش واحد';

  @override
  String get unit_name => 'نام واحد';

  @override
  String get unit_symbol => 'نماد (اختیاری)';

  @override
  String get unit_description => 'توضیحات (اختیاری)';

  @override
  String get add => 'افزودن';

  @override
  String get delete_unit => 'حذف واحد';

  @override
  String unit_delete_confirm(Object unit) {
    return 'آیا مطمئن هستید که می‌خواهید \"$unit\" را حذف کنید؟ این عمل قابل بازگشت نیست.';
  }

  @override
  String get no_units => 'هیچ واحدی یافت نشد. اولین واحد خود را اضافه کنید.';

  @override
  String get manageCategories => 'مدیریت کتگوری‌ها';

  @override
  String get noCategoriesFound =>
      'هیچ دسته‌ای یافت نشد. اولین دسته خود را اضافه کنید.';

  @override
  String get addCategory => 'افزودن کتگوری';

  @override
  String get editCategory => 'ویرایش کتگوری';

  @override
  String get categoryName => 'نام کتگوری';

  @override
  String get deleteCategory => 'حذف کتگوری';

  @override
  String confirmDeleteCategory(Object name) {
    return 'آیا مطمئن هستید که می‌خواهید \"$name\" را حذف کنید؟ این عملیات قابل بازگشت نیست.';
  }

  @override
  String get newStockMovement => 'انتقال جدید موجودی';

  @override
  String get selectProduct => 'لطفاً یک جنس انتخاب کنید';

  @override
  String get sourceWarehouse => 'انبار مبدأ';

  @override
  String get selectSourceWarehouse => 'لطفاً انبار مبدأ را انتخاب کنید';

  @override
  String get destinationWarehouse => 'انبار مقصد';

  @override
  String get selectDestinationWarehouse => 'لطفاً انبار مقصد را انتخاب کنید';

  @override
  String get enterQuantity => 'لطفاً تعداد را وارد کنید';

  @override
  String get enterValidNumber => 'لطفاً یک عدد معتبر وارد کنید';

  @override
  String get errorRecordingMovement => 'خطا در ثبت انتقال موجودی';

  @override
  String get addNewWarehouse => 'افزودن انبار جدید';

  @override
  String get warehouseName => 'نام انبار';

  @override
  String get enterWarehouseName => 'لطفاً نام انبار را وارد کنید';

  @override
  String get enterAddress => 'لطفاً آدرس را وارد کنید';

  @override
  String errorCreatingWarehouse(Object error) {
    return 'خطا در ایجاد انبار: $error';
  }

  @override
  String get editWarehouse => 'ویرایش انبار';

  @override
  String get name => 'نام';

  @override
  String get enterName => 'لطفاً نام را وارد کنید';

  @override
  String get enterWarehouseDescriptionOptional =>
      'توضیحات انبار را وارد کنید (اختیاری)';

  @override
  String get pleaseSelectWarehouse => 'لطفاً یک انبار انتخاب کنید';

  @override
  String get pleaseEnterQuantity => 'لطفاً تعداد را وارد کنید';

  @override
  String get enterValidQuantity => 'تعداد معتبر وارد کنید';

  @override
  String get move => 'انتقال';

  @override
  String get addNewProduct => 'افزودن جنس جدید';

  @override
  String get productName => 'نام جنس';

  @override
  String get pleaseEnterProductName => 'لطفاً نام جنس را وارد کنید';

  @override
  String get pleaseSelectCategory => 'لطفاً یک کتگوری انتخاب کنید';

  @override
  String get pleaseSelectUnit => 'لطفاً یک واحد انتخاب کنید';

  @override
  String get pleaseEnterMinimumStock => 'لطفاً حداقل موجودی را وارد کنید';

  @override
  String get pleaseEnterValidNumber => 'لطفاً عدد معتبری وارد کنید';

  @override
  String get barcodeOptional => 'بارکد (اختیاری)';

  @override
  String get hasExpiryDate => 'دارای تاریخ انقضا';

  @override
  String get categoryDeleted => 'کتگوری با موفقیت حذف شد.';

  @override
  String get paymentForInvoice => 'رسید برای فاکتور';

  @override
  String get status => 'وضعیت';

  @override
  String get backupCanceledNoLocation =>
      'پشتیبان‌گیری لغو شد. موقعیت انتخاب نشده است';

  @override
  String get selectBackupLocation => 'انتخاب مکان پشتیبان‌گیری';

  @override
  String get copyBalance => 'کاپی بیلانس';

  @override
  String get balanceCopied => 'بیلانس به کلیپ‌بورد کاپی شد';

  @override
  String get productAdded => 'جنس اضافه شد';

  @override
  String get productUpdated => 'جنس به‌روزرسانی شد';

  @override
  String get movementRecorded => 'جابجایی ثبت شد';

  @override
  String get movementUpdated => 'جابجایی به‌روزرسانی شد';

  @override
  String get editStockMovement => 'ویرایش جابجایی موجودی';

  @override
  String get categoryRequired => 'دسته‌بندی الزامی است';

  @override
  String get unitRequired => 'واحد الزامی است';

  @override
  String get minStockRequired => 'حداقل موجودی الزامی است';

  @override
  String get invalidNumber => 'عدد نامعتبر';

  @override
  String get reorderPointRequired => 'نقطه سفارش مجدد الزامی است';

  @override
  String get brand => 'برند';

  @override
  String get isActive => 'فعال است';

  @override
  String get cancelInvoice => 'لغو فاکتور';

  @override
  String get cancelInvoiceConfirmation =>
      'آیا از لغو این فاکتور اطمینان دارید؟ این کار موجودی کالا را برگردانده و از جزئیات حساب حذف می‌کند.';

  @override
  String get invoiceCancelled => 'فاکتور لغو شد';

  @override
  String get yes => 'بلی';

  @override
  String get no => 'نخیر';

  @override
  String get summary => 'خلاصه';

  @override
  String get newExchange => 'تبادله جدید';

  @override
  String get editExchange => 'ویرایش تبادله';

  @override
  String get refresh => 'تازه کردن';

  @override
  String get addPurchase => 'خرید جدید';

  @override
  String get refreshPurchases => 'بروزرسانی خریدها';

  @override
  String get searchPurchases => 'جستجوی خریدها...';

  @override
  String get noPurchasesFound => 'خریدی یافت نشد';

  @override
  String get purchaseDeleted => 'خرید با موفقیت حذف شد';

  @override
  String get deletePurchase => 'حذف خرید';

  @override
  String get deletePurchaseConfirmation =>
      'آیا از حذف این خرید اطمینان دارید؟ این عمل قابل بازگشت نیست.';

  @override
  String get referenceNumber => 'شماره مرجع';

  @override
  String get requiredField => 'این فیلد الزامی است';

  @override
  String get item => 'قلم';

  @override
  String get price => 'نرخ';

  @override
  String get purchaseDetails => 'جزئیات خرید';

  @override
  String get editPurchase => 'ویرایش خرید';

  @override
  String get unit_conversion => 'تبدیل واحد';

  @override
  String get conversion_rate => 'نرخ تبدیل';

  @override
  String get sales => 'فروشات';

  @override
  String get noUnitsAvailable => 'واحدی در دسترس نیست';

  @override
  String get manageUnits => 'مدیریت واحدها';

  @override
  String get conversionRate => 'نرخ تبدیل';

  @override
  String get setBaseUnit => 'تنظیم واحد پایه';

  @override
  String get deleteUnit => 'حذف واحد';

  @override
  String get noUnits => 'هیچ واحدی وجود ندارد';

  @override
  String get addUnit => 'افزودن واحد';

  @override
  String get additionalInfo => 'اطلاعات بیشتر';

  @override
  String get divide => 'تقسیم (/)';

  @override
  String errorLoadingAccounts(Object e) {
    return 'خطا در بارگذاری حساب‌ها: $e';
  }

  @override
  String errorLoadingExchangeData(Object e) {
    return 'خطا در بارگذاری داده‌های تبادله: $e';
  }

  @override
  String genericError(Object error) {
    return 'خطا: $error';
  }

  @override
  String get exchangeDetails => 'جزئیات تبادله';

  @override
  String get expectedRateOptional => 'نرخ مورد انتظار (اختیاری)';

  @override
  String get fromAccount => 'از حساب';

  @override
  String get fromCurrency => 'از ارز';

  @override
  String get multiply => 'ضرب (*)';

  @override
  String get selectBothAccounts => 'لطفاً هر دو حساب را انتخاب کنید';

  @override
  String get resultAmount => 'مقدار نتیجه';

  @override
  String get saveExchange => 'ذخیره تبادله';

  @override
  String get toAccount => 'به حساب';

  @override
  String get toCurrency => 'به ارز';

  @override
  String get operator => 'عملیه';

  @override
  String get rate => 'نرخ';

  @override
  String get profitLoss => 'سود/زیان:';

  @override
  String get errorRefreshingData => 'خطا در به‌روزرسانی داده‌ها';

  @override
  String get deleteExchangeTitle => 'حذف تبادله';

  @override
  String get deleteExchangeConfirm => 'آیا از حذف این تبادله اطمینان دارید؟';

  @override
  String get exchangeDeleted => 'تبادله با موفقیت حذف شد';

  @override
  String get errorDeletingExchange => 'خطا در حذف تبهادل';

  @override
  String get additionalCost => 'هزینه اضافی';

  @override
  String get totalCost => 'هزینه کل';

  @override
  String get costPerUnit => 'هزینه هر واحد';

  @override
  String get purchaseReports => 'گزارش خریدها';

  @override
  String get purchaseReportsDesc =>
      'مشاهده و تحلیل تمام معاملات خرید با فیلترها و خلاصه‌ها.';

  @override
  String totalPurchases(Object count) {
    return 'تعداد خریدها: $count';
  }

  @override
  String totalAmount(Object amount) {
    return 'مبلغ کل: $amount';
  }

  @override
  String get suppliers => 'فراهم کنندگان';

  @override
  String get customers => 'مشتریان';

  @override
  String get salesReports => 'گزارش فروشات';

  @override
  String get salesReportsDesc =>
      'مشاهده و تحلیل تمام معاملات فروش با فیلترها و خلاصه‌ها.';

  @override
  String totalInvoices(Object count) {
    return 'تعداد فاکتورها: $count';
  }

  @override
  String get totalIsRequired => 'مجموع الزامی است';

  @override
  String get totalMustBePositive => 'مجموع باید مثبت باشد';

  @override
  String get invalidTotalFormat => 'فرمت مجموع نامعتبر است';

  @override
  String get adjustedUp => 'افزایش یافته به میزان';

  @override
  String get adjustedDown => 'کاهش یافته به میزان';

  @override
  String get manualTotalAdjustment => 'تنظیم دستی مجموع';

  @override
  String get calculatedTotal => 'مجموع محاسبه شده';

  @override
  String get finalTotal => 'مجموع نهایی';

  @override
  String get unit_conversion_management => 'مدیریت تبدیل واحدها';

  @override
  String get add_unit_conversion => 'افزودن تبدیل واحد';

  @override
  String get edit_unit_conversion => 'ویرایش تبدیل واحد';

  @override
  String get delete_unit_conversion => 'حذف تبدیل واحد';

  @override
  String get unit_conversion_delete_confirm =>
      'آیا مطمئن هستید که می‌خواهید این تبدیل واحد را حذف کنید؟ این عمل قابل بازگشت نیست.';

  @override
  String get unit_conversion_deleted => 'تبدیل واحد با موفقیت حذف شد.';

  @override
  String get no_unit_conversions => 'هیچ تبدیل واحدی یافت نشد.';

  @override
  String get from_unit => 'از واحد';

  @override
  String get to_unit => 'به واحد';

  @override
  String get deleteStockMovementAuthMessage =>
      'لطفاً برای حذف این حرکت انبار احراز هویت کنید';

  @override
  String get confirmDeleteStockMovement =>
      'آیا مطمئن هستید که می‌خواهید این حرکت انبار را حذف کنید؟ این عملیات قابل بازگشت نیست.';

  @override
  String get stockMovementDeleted => 'حرکت انبار با موفقیت حذف شد.';

  @override
  String get errorDeletingStockMovement => 'خطا در حذف حرکت انبار.';

  @override
  String get unitCostWithAdditional => 'تمام شد جنس:';

  @override
  String get stockMovementReports => 'گزارش جابجایی موجودی‌ها';

  @override
  String get stockMovementReportsDesc =>
      'نمایش و تحلیل تمام جابجایی‌های ورودی/خروجی/انتقال موجودی با فیلتر و خلاصه.';

  @override
  String get totalIn => 'ورودی کل';

  @override
  String get totalOut => 'خروجی کل';

  @override
  String get netMovement => 'جابجایی خالص';

  @override
  String get manageDatabaseBackups => 'مدیریت پشتیبان‌گیری دیتابیس';

  @override
  String get backupDescription =>
      'پشتیبان‌گیری آنلاین و محلی از دیتابیس خود ایجاد کنید یا در صورت نیاز داده‌ها را بازیابی کنید.';

  @override
  String get enterYourCurrentAndNewPassword =>
      'لطفاً رمز عبور فعلی را وارد کرده و یک رمز جدید انتخاب کنید.';

  @override
  String get showPassword => 'نمایش رمز عبور';

  @override
  String get hidePassword => 'مخفی کردن رمز عبور';

  @override
  String get actions => 'عملیات';

  @override
  String get newSale => 'فروش جدید';

  @override
  String get unitName => 'نام واحد';

  @override
  String get fromUnit => 'از واحد';

  @override
  String get toUnit => 'به واحد';

  @override
  String get bill => 'صورت حساب';

  @override
  String get stockValueReports => 'گزارش‌های ارزش موجودی';

  @override
  String get stockValueReportsDesc =>
      'مشاهده ارزش‌های موجودی فعلی با قیمت‌گذاری و خلاصه‌ها';

  @override
  String get detailed => 'جزئیات';

  @override
  String get byWarehouse => 'بر اساس انبار';

  @override
  String get byProduct => 'بر اساس محصول';

  @override
  String get byCurrency => 'بر اساس ارز';

  @override
  String get expiryDateFrom => 'تاریخ انقضا از';

  @override
  String get expiryDateTo => 'تاریخ انقضا تا';

  @override
  String errorLoadingData(Object error) {
    return 'خطا در بارگذاری اطلاعات: $error';
  }

  @override
  String get totalValue => 'ارزش کل';

  @override
  String get totalQuantity => 'مقدار کل';

  @override
  String get stockValueByCurrency => 'ارزش موجودی بر اساس ارز';

  @override
  String get stockValue => 'ارزش موجودی';

  @override
  String get allProducts => 'همه محصولات';

  @override
  String get na => 'نامشخص';

  @override
  String get totalProducts => 'کل محصولات';

  @override
  String get totalWarehouses => 'کل انبارها';

  @override
  String get aboutDescription =>
      'وترا یک شرکت پیشرو در زمینه فناوری است که در راه‌حل‌های نوآورانه کسب‌وکار و تحول دیجیتال تخصص دارد. ما کسب‌وکارها را با فناوری‌های پیشرفته توانمند می‌کنیم تا رشد و موفقیت را در عصر دیجیتال هدایت کنند.';

  @override
  String get companyTagline => 'توانمندسازی کسب‌وکار از طریق فناوری';

  @override
  String get followUs => 'ما را دنبال کنید';

  @override
  String get contactInfo => 'اطلاعات تماس';

  @override
  String get companyAddress => 'کابل، افغانستان';

  @override
  String get allRightsReserved => 'تمامی حقوق محفوظ است';

  @override
  String get helpTitle => 'راهنما و پشتیبانی';

  @override
  String get helpDescription =>
      'نیاز به راهنمایی دارید؟ با تیم پشتیبانی ما تماس بگیرید.';

  @override
  String get financialBalance => 'بیلانس مالی';

  @override
  String get financialBalanceDesc =>
      'مشاهده بیلانس حساب‌ها و شناسایی بدهی‌ها و مطالبات';

  @override
  String get totalPayable => 'کل بدهی';

  @override
  String get totalReceivable => 'کل مطالبات';

  @override
  String get payableToOthers => 'شما به دیگران بدهکار هستید';

  @override
  String get receivableFromOthers => 'دیگران به شما بدهکار هستند';

  @override
  String get netBalance => 'بیلانس خالص';

  @override
  String get positiveBalance => 'بیلانس مثبت';

  @override
  String get negativeBalance => 'بیلانس منفی';

  @override
  String get zeroBalance => 'بیلانس صفر';

  @override
  String get balanceStatus => 'وضعیت بیلانس';

  @override
  String get lastTransaction => 'آخرین معامله';

  @override
  String get noTransactions => 'معامله‌ای یافت نشد';

  @override
  String shareTransactionGreeting(String accountName) {
    return 'محترم $accountName،\n';
  }

  @override
  String shareTransactionMessage(
      String amount, String currency, String transactionType, String date) {
    return 'مبلغ $amount $currency در تاریخ \n$date\n به حساب شما $transactionType شده است.';
  }

  @override
  String get shareTransactionBalanceHeader => 'بیلانس فعلی حساب:';

  @override
  String shareTransactionDescription(String description) {
    return 'توضیحات: $description';
  }

  @override
  String shareTransactionSignature(String companyName) {
    return 'با احترام،\n$companyName';
  }

  @override
  String get creditTransactionType => 'آوردگی';

  @override
  String get debitTransactionType => 'بردگی';

  @override
  String get filterByAccountType => 'فیلتر بر اساس نوع حساب';

  @override
  String get filterByCurrency => 'فیلتر بر اساس ارز';

  @override
  String get showAll => 'نمایش همه';

  @override
  String get noFinancialDataAvailable => 'هیچ داده مالی موجود نیست';

  @override
  String get addAccountsTransactionsMessage =>
      'برای مشاهده بیلانس مالی خود، چند حساب و معامله اضافه کنید';

  @override
  String get clearCacheRefresh => 'پاک کردن کش و به‌روزرسانی';

  @override
  String get processingAccounts => 'در حال پردازش حساب‌ها...';

  @override
  String get batchProcessing => 'پردازش دسته‌ای برای عملکرد بهتر';

  @override
  String get receivable => 'دریافتنی‌ها';

  @override
  String get payable => 'پرداختنی‌ها';

  @override
  String get totalSales => 'فروش کل';

  @override
  String get copiedToClipboard => 'به حافظه موقت کاپی شد';

  @override
  String get sortByTotalDesc => 'جمع کل (بیشترین به کمترین)';

  @override
  String get sortByNameAsc => 'نام (الف تا ی)';

  @override
  String get sortByNameDesc => 'نام (ی تا الف)';

  @override
  String get sortByQuantityDesc => 'تعداد (بیشترین به کمترین)';

  @override
  String get send => 'ارسال';

  @override
  String get copy => 'کاپی';
}
