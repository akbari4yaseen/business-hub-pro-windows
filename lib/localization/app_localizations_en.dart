// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BusinessHub Pro';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFarsi => 'Farsi';

  @override
  String get languagePashto => 'Pashto';

  @override
  String get home => 'Home';

  @override
  String get journal => 'Journal';

  @override
  String get accounts => 'Accounts';

  @override
  String get exchange => 'Exchange';

  @override
  String get accountsPrint => 'Accounts';

  @override
  String get reports => 'Reports';

  @override
  String get inventory => 'Inventory';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get addAccount => 'New Account';

  @override
  String get addJournal => 'New Journal';

  @override
  String get editJournal => 'Edit Journal';

  @override
  String get accountName => 'Account Name';

  @override
  String get accountType => 'Account Type';

  @override
  String get customer => 'Customer';

  @override
  String get employee => 'Employee';

  @override
  String get supplier => 'Supplier';

  @override
  String get exchanger => 'Exchanger';

  @override
  String get system => 'System';

  @override
  String get phone => 'Phone';

  @override
  String get call => 'Call';

  @override
  String get callError => 'Unable to place call';

  @override
  String get address => 'Address';

  @override
  String get save => 'Save';

  @override
  String get nameRequired => 'Name is required!';

  @override
  String get treasure => 'Treasure';

  @override
  String get noTreasure => 'No Treasure';

  @override
  String get asset => 'Asset';

  @override
  String get profit => 'Profit';

  @override
  String get loss => 'Loss';

  @override
  String get expenses => 'Expenses';

  @override
  String get activeAccounts => 'Active Accounts';

  @override
  String get deactivatedAccounts => 'Deactivated Accounts';

  @override
  String get transactions => 'Account Transactions';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get reactivateAccount => 'Reactivate Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeactivate => 'Confirm Deactivation';

  @override
  String get confirmReactivate => 'Confirm Reactivation';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get shareBalance => 'Share Balance';

  @override
  String get sendBalance => 'Send Balance';

  @override
  String get invalidPhone => 'Invalid Phone Number';

  @override
  String get saveError => 'Error in saving data';

  @override
  String get existsAccountError => 'An account with this name already exists';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get selectTrack => 'Select Track';

  @override
  String get credit => 'Credit';

  @override
  String get debit => 'Debit';

  @override
  String get credited => 'Credited';

  @override
  String get debited => 'Debited';

  @override
  String get track => 'Track';

  @override
  String get typeToSearchTrack => 'Type to search track';

  @override
  String get pleaseSelectTrack => 'Please select a track';

  @override
  String get pleaseSelectAccount => 'Please select an account';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get search => 'Search';

  @override
  String get purchases => 'Purchases';

  @override
  String get searchJournal => 'Search journals...';

  @override
  String deleteAccountConfirm(Object accountName) {
    return 'Are you sure you want to delete $accountName?';
  }

  @override
  String deactivateAccountConfirm(Object accountName) {
    return 'Are you sure you want to deactivate account $accountName?';
  }

  @override
  String reactivateAccountConfirm(Object accountName) {
    return 'Do you want to reactivate account $accountName?';
  }

  @override
  String get noAccountsAvailable => 'No accounts available';

  @override
  String get noMoreAccounts => 'No more accounts';

  @override
  String get searchAccount => 'Search accounts...';

  @override
  String get all => 'All';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get incorrectCurrentPassword => 'Current password is incorrect';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get passwordTooShort => 'Must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get loginHeader => 'Login to the system';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get enterPassword => 'Please enter your password.';

  @override
  String get wrongPassword => 'Incorrect password.';

  @override
  String get appName => 'BusinessHubPro';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get logout => 'Logout';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get backupTitle => 'Backup Database';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get exportCanceledNoDirectory =>
      'Export canceled. No directory selected.';

  @override
  String databaseExportedSuccessfully(Object path) {
    return 'Database exported successfully to:\n$path';
  }

  @override
  String get databaseFileNotFoundOrExportFailed =>
      'Database file not found or export failed!';

  @override
  String errorExportingDatabase(Object error) {
    return 'Error exporting database: $error';
  }

  @override
  String get restoreCanceledNoFile => 'Restore canceled. No file selected.';

  @override
  String get databaseRestoredSuccessfully =>
      'Database restored successfully! Please restart the app.';

  @override
  String get restoreFailedFileNotFound =>
      'Restore failed! File not found or error occurred.';

  @override
  String errorRestoringDatabase(Object error) {
    return 'Error restoring database: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get companyInfo => 'Company Info';

  @override
  String themeMode(Object mode) {
    return 'Mode: $mode';
  }

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get filters => 'Filters';

  @override
  String get filter => 'Filter';

  @override
  String get maxBalance => 'Max Balance';

  @override
  String get positiveNegativeBalances => 'Positive / Negative Balances';

  @override
  String get showPositiveBalances => 'Show Positive Balances';

  @override
  String get showNegativeBalances => 'Show Negative Balances';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get defaultTransactionType => 'Default Transaction Type';

  @override
  String get defaultTrack => 'Default Track';

  @override
  String get appLanguage => 'App Language';

  @override
  String get businessName => 'Business Name';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get email => 'Email';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get companyInfoUpdated => 'Company information updated successfully';

  @override
  String get companyInfoUpdateError => 'Failed to update company information';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get confirmDeleteJournal =>
      'Are you sure you want to delete this journal entry? This action cannot be undone.';

  @override
  String get journalDetails => 'Transaction Details';

  @override
  String get noDescription => 'No Description';

  @override
  String get date => 'Date';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get account => 'Account';

  @override
  String get close => 'Close';

  @override
  String get details => 'Details';

  @override
  String get share => 'Share';

  @override
  String get edit => 'Edit';

  @override
  String get printDisabled => 'Print (Disabled)';

  @override
  String get print => 'Print';

  @override
  String get noJournalEntries => 'No journal entries found.';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get accountFilters => 'Account Filters';

  @override
  String get balanceRange => 'Balance Range';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get balanceType => 'Balance Type';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get maxAmount => 'Max Amount';

  @override
  String get minAmount => 'Min Amount';

  @override
  String get apply => 'Apply';

  @override
  String get balance => 'Balance';

  @override
  String get selectDate => 'Select Date';

  @override
  String get currency => 'Currency';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get bank => 'Bank';

  @override
  String get owner => 'Owner';

  @override
  String get company => 'Company';

  @override
  String get errorDeletingJournal =>
      'Error deleting journal. Please try again.';

  @override
  String get errorLoadingJournal =>
      'Error loading journal entries. Please try again.';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to back up.';

  @override
  String shareMessageHeader(Object name) {
    return '📢 Dear *$name*,\n\nHere is the detailed summary of your account balances across all available currencies. This report reflects the most recent transactions recorded in our system.\n\nPlease review the balances below carefully to stay updated and avoid any potential discrepancies.\n\n*Balances:*';
  }

  @override
  String shareMessageTimestamp(Object date) {
    return '*Timestamp:* $date';
  }

  @override
  String shareMessageFooter(Object appName) {
    return '---------------\n$appName';
  }

  @override
  String get shareMessagePaymentReminder =>
      '💡 *Please pay the remaining balance.*';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get statsLoadError => 'Error loading account stats';

  @override
  String get allAccounts => 'All';

  @override
  String get activeAccountsShort => 'Active';

  @override
  String get deactivatedAccountsShort => 'Inactive';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noRecentTransactions => 'No recent transactions';

  @override
  String get noTransactionsFound => 'No transactions';

  @override
  String get noExchangesFound => 'No exchanges found';

  @override
  String get transactionEditError => 'Failed to edit Transaction';

  @override
  String get transactionNotFound => 'Journal transaction not found';

  @override
  String get transactionDeleteError => 'Failed to delete Transaction';

  @override
  String get onlineBackupSuccess => 'Online backup successful';

  @override
  String get onlineBackupFailed => 'Online backup failed';

  @override
  String get localBackupSuccess => 'Local backup successful';

  @override
  String get localBackupFailed => 'Local backup failed';

  @override
  String get confirmRestore => 'Confirm Restore';

  @override
  String get restoreOverwriteWarning =>
      'This will overwrite existing data. Continue?';

  @override
  String get restoreSuccess => 'Database restored successfully';

  @override
  String get restoreFailed => 'Database restore failed';

  @override
  String get databaseSettings => 'Database Settings';

  @override
  String get baseUnit => 'Base Unit';

  @override
  String get lastOnlineBackup => 'Last Online Backup';

  @override
  String get lastOfflineBackup => 'Last Offline Backup';

  @override
  String get backupOnline => 'Backup Online';

  @override
  String get backupLocal => 'Backup Local';

  @override
  String get restoreDatabase => 'Restore Database';

  @override
  String get reminders => 'Reminders';

  @override
  String get reminder => 'Reminder';

  @override
  String get systemAccount => 'System Account';

  @override
  String get error => 'Error';

  @override
  String get noSystemAccountsFound => 'No system accounts found.';

  @override
  String get currencies => 'Currencies';

  @override
  String get current => 'Current';

  @override
  String get noDataAvailable => 'No Data Available';

  @override
  String get accountReports => 'Account Reports';

  @override
  String get accountReportsDesc => 'Account balances, and more';

  @override
  String get dailyBalancesDesc => 'Line chart showing daily account balances';

  @override
  String get systemAccountReports => 'System Account Reports';

  @override
  String get systemAccountReportsDesc => 'List of system accounts and balances';

  @override
  String get moreVisualizations => 'More Visualizations';

  @override
  String get moreVisualizationsDesc =>
      'Future charts and analytics will appear here';

  @override
  String get accountLabel => 'Account';

  @override
  String get currentLabel => 'Current balance';

  @override
  String get periodWeek => '1W';

  @override
  String get periodMonth => '1M';

  @override
  String get period3Months => '3M';

  @override
  String get period6Months => '6M';

  @override
  String get periodYear => '1Y';

  @override
  String get period3Years => '3Y';

  @override
  String get periodAll => 'All';

  @override
  String get metricCurrentBalance => 'Current Balance';

  @override
  String get metricChange => 'Change';

  @override
  String get dailyBalances => 'Daily Balances';

  @override
  String get accountBalances => 'Account Balances';

  @override
  String get accountsByType => 'Accounts by Type';

  @override
  String balanceLabel(Object currency) {
    return 'Balance ($currency)';
  }

  @override
  String totalCount(Object count) {
    return 'Total: $count';
  }

  @override
  String printed(Object date) {
    return 'Printed: $date';
  }

  @override
  String pageOf(Object page, Object total) {
    return 'Page $page of $total';
  }

  @override
  String get number => 'No.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get deleteReminderTitle => 'Delete Reminder';

  @override
  String get deleteReminderConfirmation =>
      'Are you sure you want to delete this reminder?';

  @override
  String get noRemindersYet => 'No reminders yet!';

  @override
  String get newReminderTitle => 'New Reminder';

  @override
  String get editReminderTitle => 'Edit Reminder';

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dateTimeLabel => 'Date & Time';

  @override
  String get repeatLabel => 'Repeat';

  @override
  String get intervalLabel => 'Interval';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get defaultReminder => 'Time for your reminder!';

  @override
  String get repeats => 'Repeats';

  @override
  String get titleEmptyError => 'Please enter a title';

  @override
  String get pickDateTimeError => 'Please pick date & time';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllReadTooltip => 'Mark all as read';

  @override
  String get clearAllTooltip => 'Clear all';

  @override
  String get clearAllNotificationsTitle => 'Clear All Notifications';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get clearAllNotificationsContent =>
      'Are you sure you want to clear all notifications?';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get undo => 'UNDO';

  @override
  String get loading => 'Loading...';

  @override
  String get useFingerprint => 'Use fingerprint';

  @override
  String get biometricReason => 'Please authenticate to access BusinessHubPro';

  @override
  String get biometricError => 'Biometric authentication failed';

  @override
  String get backupCardFriendlyMessage =>
      'Keep your data safe! Remember to back up regularly.';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get enterPasswordError => 'Enter password';

  @override
  String get authTitle => 'Authenticate';

  @override
  String get biometricFailed => 'Biometric authentication failed';

  @override
  String get deleteAccountAuthMessage =>
      'Deleting an Account requires authentication';

  @override
  String get deleteJournalAuthMessage =>
      'Please authenticate to delete this Journal';

  @override
  String get confirmDeleteTransaction =>
      'Please authenticate to delete this Transaction';

  @override
  String get journalSaved => 'Journal saved';

  @override
  String get errorSavingJournal => 'Error saving Journal';

  @override
  String get printSettings => 'Print Settings';

  @override
  String get preparingPrint => 'Preparing print...';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String shareMessage(Object accountName, Object action, Object amount,
      Object currency, Object date, Object description, Object footer) {
    return 'Dear $accountName,\n\nYour account has been $action with $amount $currency on $date.\n\nExtra Description: $description\n\n$footer';
  }

  @override
  String get onlineBackupOverdueTitle => 'Online Backup Overdue';

  @override
  String get onlineBackupOverdueMessage =>
      'Your last online backup was more than 7 days ago. Please back up your data online.';

  @override
  String get offlineBackupOverdueTitle => 'Offline Backup Overdue';

  @override
  String get offlineBackupOverdueMessage =>
      'Your last offline backup was more than 7 days ago. Please back up your data locally.';

  @override
  String accountInactiveTitle(Object name) {
    return 'The account \"$name\" is inactive';
  }

  @override
  String accountInactiveMessage(Object days, Object name) {
    return 'The account \"$name\" has had no transactions in the last $days days.';
  }

  @override
  String get inactivityDays =>
      'The number of days an account has no transaction';

  @override
  String get periodicReports => 'Periodic Reports';

  @override
  String get periodicReportsDesc => 'View credit/debit balances over time';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last14Days => 'Last 14 Days';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get last3Months => 'Last 3 Months';

  @override
  String get last6Months => 'Last 6 Months';

  @override
  String get lastYear => 'Last Year';

  @override
  String get customRange => 'Custom Range';

  @override
  String get period => 'Period';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get totalCredit => 'Total Credit';

  @override
  String get totalDebit => 'Total Debit';

  @override
  String get pleaseSelectAllFilters => 'Please select all filters';

  @override
  String get pleaseSelectDateRange => 'Please select date range';

  @override
  String get product => 'Product';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get total => 'Total';

  @override
  String get unknownProduct => 'Unknown Product';

  @override
  String get invoice => 'Invoice';

  @override
  String get invoiceDate => 'Invoice Date';

  @override
  String get dueDate => 'Due Date';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get balanceDue => 'Balance Due';

  @override
  String get notes => 'Notes';

  @override
  String get note => 'Note';

  @override
  String get soldGoodsNotReturnable => 'Sold goods are not returnable';

  @override
  String get sells => 'Sells';

  @override
  String get inventoryManagement => 'Inventory Management';

  @override
  String get currentStock => 'Current Stock';

  @override
  String get products => 'Products';

  @override
  String get warehouses => 'Warehouses';

  @override
  String get stockMovements => 'Stock Movements';

  @override
  String get invoices => 'Invoices';

  @override
  String get allInvoices => 'All Invoices';

  @override
  String get overdue => 'Overdue';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String failedRecordPayment(Object error) {
    return 'Failed to record payment: $error';
  }

  @override
  String failedFinalizeInvoice(Object error) {
    return 'Failed to finalize invoice: $error';
  }

  @override
  String get confirmFinalizeInvoice => 'Confirm Invoice Finalization';

  @override
  String get finalizeInvoiceConfirmation =>
      'Are you sure you want to finalize this invoice? This action cannot be undone.';

  @override
  String get noInvoices => 'No invoices found';

  @override
  String get noOverdueInvoices => 'No overdue invoices';

  @override
  String customerInvoice(Object name) {
    return 'Customer: $name';
  }

  @override
  String dateInvoice(Object date) {
    return 'Date: $date';
  }

  @override
  String dueInvoice(Object date) {
    return 'Due: $date';
  }

  @override
  String totalInvoice(Object amount) {
    return 'Total: $amount';
  }

  @override
  String paidInvoice(Object amount) {
    return 'Paid: $amount';
  }

  @override
  String balanceInvoice(Object amount) {
    return 'Balance: $amount';
  }

  @override
  String overdueByInvoice(Object days) {
    return 'Overdue by $days days';
  }

  @override
  String get finalize => 'Finalize';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get editInvoice => 'Edit Invoice';

  @override
  String get deleteInvoice => 'Delete Invoice';

  @override
  String get printInvoice => 'Print Invoice';

  @override
  String get items => 'Items';

  @override
  String get deleteInvoiceConfirmation =>
      'Are you sure you want to delete this invoice?';

  @override
  String get invoiceDeleted => 'Invoice deleted successfully';

  @override
  String get errorDeletingInvoice => 'Error deleting invoice';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get invoiceLabel => 'Invoice';

  @override
  String get outstandingBalance => 'Outstanding Balance';

  @override
  String get paymentAmount => 'Payment Amount';

  @override
  String get pleaseEnterPaymentAmount => 'Please enter payment amount';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get amountGreaterThanZero => 'Amount must be greater than zero';

  @override
  String get amountExceedsBalance => 'Amount cannot exceed outstanding balance';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get invoiceNumberRequired => 'Invoice number is required';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerNameRequired => 'Customer name is required';

  @override
  String get invalidAmount => 'Please enter a valid amount greater than 0';

  @override
  String get invoiceSaved => 'Invoice saved successfully';

  @override
  String get notSet => 'Not set';

  @override
  String get addItem => 'Add Item';

  @override
  String get noItemsAdded => 'No items added yet. Press \"Add Item\" to begin.';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get noCustomersFound =>
      'No customers found. Please add a customer account first.';

  @override
  String get customerAccount => 'Customer Account';

  @override
  String get pleaseSelectProductForAllItems =>
      'Please select a product for all items';

  @override
  String get quantityMustBeGreaterThanZero =>
      'Quantity must be greater than 0 for all items';

  @override
  String get updating => 'Updating';

  @override
  String get creating => 'Creating';

  @override
  String get noProductsAvailable =>
      'No products available. Please add products first.';

  @override
  String warningNoStockFor(Object product) {
    return 'Warning: No stock available for';
  }

  @override
  String get availableStock => 'Available Stock';

  @override
  String get noStockAvailable => 'No stock available';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get remove => 'Remove';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get required => 'Required';

  @override
  String get notEnoughStock => 'Not enough stock';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String get stock => 'Stock';

  @override
  String get pleaseSelectProduct => 'Please select a product';

  @override
  String get invoiceStatusDraft => 'Draft';

  @override
  String get invoiceStatusFinalized => 'Finalized';

  @override
  String get invoiceStatusPartiallyPaid => 'Partially Paid';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get preSale => 'Pre-Sale';

  @override
  String get isPreSale => 'Is Pre-Sale';

  @override
  String get preSaleDescription =>
      'Pre-sale invoices allow selling products without checking stock availability';

  @override
  String get preSaleWarning =>
      'e-sale mode: Stock availability will not be checked';

  @override
  String get retry => 'Retry';

  @override
  String get activeFilters => 'Active filters';

  @override
  String get clearAll => 'Clear all';

  @override
  String get lowStockAlerts => 'Low Stock Alerts';

  @override
  String get expiringProducts => 'Expiring Products';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get warehouse => 'Warehouse';

  @override
  String get allWarehouses => 'All Warehouses';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get location => 'Location';

  @override
  String get expires => 'Expires';

  @override
  String get sku => 'SKU';

  @override
  String get unit => 'Unit';

  @override
  String get minimumStock => 'Minimum Stock';

  @override
  String get maximumStock => 'Maximum Stock';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get lastMovement => 'Last Movement';

  @override
  String get moveStock => 'Move Stock';

  @override
  String get adjustQuantity => 'Adjust Quantity';

  @override
  String get viewHistory => 'View History';

  @override
  String get refreshProducts => 'Refresh Products';

  @override
  String get categories => 'Categories';

  @override
  String get units => 'Units';

  @override
  String get showInactive => 'Show Inactive';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get changeSearchCriteria => 'Try changing your search criteria';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get activate => 'Activate';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String deleteConfirm(Object productName) {
    return 'Are you sure you want to delete $productName?';
  }

  @override
  String get deleteSuccess => 'Product deleted successfully';

  @override
  String get activatedSuccess => 'Product activated successfully';

  @override
  String get deactivatedSuccess => 'Product deactivated successfully';

  @override
  String get inactive => 'Inactive';

  @override
  String get barcode => 'Barcode';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get stockSettings => 'Stock Settings';

  @override
  String get minStock => 'Min Stock';

  @override
  String get maxStock => 'Max Stock';

  @override
  String get reorderPoint => 'Reorder Point';

  @override
  String get search_warehouses => 'Search Warehouses';

  @override
  String get show_empty => 'Show Empty';

  @override
  String get refresh_warehouses => 'Refresh Warehouses';

  @override
  String get no_warehouses_found => 'No warehouses found';

  @override
  String get clear_filters => 'Clear filters';

  @override
  String get edit_warehouse => 'Edit Warehouse';

  @override
  String get delete_warehouse => 'Delete Warehouse';

  @override
  String delete_warehouse_confirm(Object name) {
    return 'Are you sure you want to delete the warehouse \"$name\"?';
  }

  @override
  String get warehouse_deleted => 'Warehouse deleted successfully';

  @override
  String get no_items_in_warehouse => 'No items in this warehouse';

  @override
  String get minimum => 'Minimum';

  @override
  String get notAvailable => 'N/A';

  @override
  String get noMovementsFound => 'No movements found';

  @override
  String get movementType => 'Movement Type';

  @override
  String get movementType_purchase => 'Purchase';

  @override
  String get purchase => 'Purchase';

  @override
  String get movementType_sale => 'Sale';

  @override
  String get allTypes => 'All Types';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get reference => 'Reference';

  @override
  String get movementDetails => 'Movement Details';

  @override
  String get type => 'Type';

  @override
  String get source => 'Source';

  @override
  String get destination => 'Destination';

  @override
  String get createdAt => 'Created At';

  @override
  String get productActivated => 'Product activated successfully';

  @override
  String get productDeactivated => 'Product deactivated successfully';

  @override
  String get productDeleted => 'Product deleted successfully';

  @override
  String confirmDeleteProduct(Object productName) {
    return 'Are you sure you want to delete $productName?';
  }

  @override
  String get movementType_stockIn => 'Stock In';

  @override
  String get movementType_stockOut => 'Stock Out';

  @override
  String get movementType_transfer => 'Transfer';

  @override
  String get movementType_adjustment => 'Adjustment';

  @override
  String get add_unit => 'Add Unit';

  @override
  String get edit_unit => 'Edit Unit';

  @override
  String get unit_name => 'Unit Name';

  @override
  String get unit_symbol => 'Symbol (Optional)';

  @override
  String get unit_description => 'Description (Optional)';

  @override
  String get add => 'Add';

  @override
  String get delete_unit => 'Delete Unit';

  @override
  String unit_delete_confirm(Object unit) {
    return 'Are you sure you want to delete \"$unit\"? This action cannot be undone.';
  }

  @override
  String get no_units => 'No units found. Add your first unit.';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get noCategoriesFound =>
      'No categories found. Add your first category.';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String confirmDeleteCategory(Object name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get newStockMovement => 'New Stock Movement';

  @override
  String get selectProduct => 'Please select a product';

  @override
  String get sourceWarehouse => 'Source Warehouse';

  @override
  String get selectSourceWarehouse => 'Please select a source warehouse';

  @override
  String get destinationWarehouse => 'Destination Warehouse';

  @override
  String get selectDestinationWarehouse =>
      'Please select a destination warehouse';

  @override
  String get enterQuantity => 'Please enter quantity';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get errorRecordingMovement => 'Error recording stock movement';

  @override
  String get addNewWarehouse => 'Add New Warehouse';

  @override
  String get warehouseName => 'Warehouse Name';

  @override
  String get enterWarehouseName => 'Please enter a warehouse name';

  @override
  String get enterAddress => 'Please enter an address';

  @override
  String errorCreatingWarehouse(Object error) {
    return 'Error creating warehouse: $error';
  }

  @override
  String get editWarehouse => 'Edit Warehouse';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get enterWarehouseDescriptionOptional =>
      'Enter warehouse description (optional)';

  @override
  String get pleaseSelectWarehouse => 'Please select a warehouse';

  @override
  String get pleaseEnterQuantity => 'Please enter a quantity';

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get move => 'Move';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get productName => 'Product Name';

  @override
  String get pleaseEnterProductName => 'Please enter a product name';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseSelectUnit => 'Please select a unit';

  @override
  String get pleaseEnterMinimumStock => 'Please enter minimum stock';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get barcodeOptional => 'Barcode (Optional)';

  @override
  String get hasExpiryDate => 'Has Expiry Date';

  @override
  String get categoryDeleted => 'Category deleted successfully.';

  @override
  String get paymentForInvoice => 'Payment for invoice';

  @override
  String get status => 'Status';

  @override
  String get backupCanceledNoLocation => 'Backup Canceled. No Location';

  @override
  String get selectBackupLocation => 'Select Backup Location';

  @override
  String get copyBalance => 'Copy Balance';

  @override
  String get balanceCopied => 'Balance copied to clipboard';

  @override
  String get productAdded => 'Product added';

  @override
  String get productUpdated => 'Product updated';

  @override
  String get movementRecorded => 'Movement recorded';

  @override
  String get movementUpdated => 'Movement updated';

  @override
  String get editStockMovement => 'Edit stock movement';

  @override
  String get categoryRequired => 'Category is required';

  @override
  String get unitRequired => 'Unit is required';

  @override
  String get minStockRequired => 'Minimum stock is required';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get reorderPointRequired => 'Reorder point is required';

  @override
  String get brand => 'Brand';

  @override
  String get isActive => 'Is active';

  @override
  String get cancelInvoice => 'Cancel Invoice';

  @override
  String get cancelInvoiceConfirmation =>
      'Are you sure you want to cancel this invoice? This will revert stock and remove from account details.';

  @override
  String get invoiceCancelled => 'Invoice cancelled';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get summary => 'Summary';

  @override
  String get newExchange => 'New Exchange';

  @override
  String get editExchange => 'Edit Exchange';

  @override
  String get refresh => 'Refresh';

  @override
  String get addPurchase => 'Add Purchase';

  @override
  String get refreshPurchases => 'Refresh Purchases';

  @override
  String get searchPurchases => 'Search purchases...';

  @override
  String get noPurchasesFound => 'No purchases found';

  @override
  String get purchaseDeleted => 'Purchase deleted successfully';

  @override
  String get deletePurchase => 'Delete Purchase';

  @override
  String get deletePurchaseConfirmation =>
      'Are you sure you want to delete this purchase? This action cannot be undone.';

  @override
  String get referenceNumber => 'Reference Number';

  @override
  String get requiredField => 'This field is required';

  @override
  String get item => 'Item';

  @override
  String get price => 'Price';

  @override
  String get purchaseDetails => 'Purchase Details';

  @override
  String get editPurchase => 'Edit Purchase';

  @override
  String get unit_conversion => 'Unit Conversion';

  @override
  String get conversion_rate => 'Conversion Rate';

  @override
  String get sales => 'Sales';

  @override
  String get noUnitsAvailable =>
      'No units available for this product. Please add units first.';

  @override
  String get manageUnits => 'Manage Units';

  @override
  String get conversionRate => 'Conversion Rate';

  @override
  String get setBaseUnit => 'Set as Base Unit';

  @override
  String get deleteUnit => 'Delete Unit';

  @override
  String get noUnits => 'No units defined. Add your first unit.';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get additionalInfo => 'Additional Information';

  @override
  String get divide => 'Divide (/)';

  @override
  String errorLoadingAccounts(Object e) {
    return 'Error loading accounts: $e';
  }

  @override
  String errorLoadingExchangeData(Object e) {
    return 'Error loading exchange data: $e';
  }

  @override
  String genericError(Object error) {
    return 'Error: $error';
  }

  @override
  String get exchangeDetails => 'Exchange Details';

  @override
  String get expectedRateOptional => 'Expected Rate (Optional)';

  @override
  String get fromAccount => 'From Account';

  @override
  String get fromCurrency => 'From Currency';

  @override
  String get multiply => 'Multiply (*)';

  @override
  String get selectBothAccounts => 'Please select both accounts';

  @override
  String get resultAmount => 'Result Amount';

  @override
  String get saveExchange => 'Save Exchange';

  @override
  String get toAccount => 'To Account';

  @override
  String get toCurrency => 'To Currency';

  @override
  String get operator => 'Operator';

  @override
  String get rate => 'Rate';

  @override
  String get profitLoss => 'Profit/Loss:';

  @override
  String get errorRefreshingData => 'Error refreshing data';

  @override
  String get deleteExchangeTitle => 'Delete Exchange';

  @override
  String get deleteExchangeConfirm =>
      'Are you sure you want to delete this exchange?';

  @override
  String get exchangeDeleted => 'Exchange deleted successfully';

  @override
  String get errorDeletingExchange => 'Error deleting exchange';

  @override
  String get additionalCost => 'Additional Cost';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get costPerUnit => 'Cost per Unit';

  @override
  String get purchaseReports => 'Purchase Reports';

  @override
  String get purchaseReportsDesc =>
      'View and analyze all purchase transactions with filters and summaries.';

  @override
  String totalPurchases(Object count) {
    return 'Total Purchases: $count';
  }

  @override
  String totalAmount(Object amount) {
    return 'Total Amount: $amount';
  }

  @override
  String get suppliers => 'Suppliers';

  @override
  String get customers => 'Customers';

  @override
  String get salesReports => 'Sales Reports';

  @override
  String get salesReportsDesc =>
      'View and analyze all sales transactions with filters and summaries.';

  @override
  String totalInvoices(Object count) {
    return 'Total Invoices: $count';
  }

  @override
  String get totalIsRequired => 'Total is required';

  @override
  String get totalMustBePositive => 'Total must be positive';

  @override
  String get invalidTotalFormat => 'Invalid total format';

  @override
  String get adjustedUp => 'Adjusted up by';

  @override
  String get adjustedDown => 'Adjusted down by';

  @override
  String get manualTotalAdjustment => 'Manual total adjustment';

  @override
  String get calculatedTotal => 'Calculated total';

  @override
  String get finalTotal => 'Final total';

  @override
  String get unit_conversion_management => 'Unit Conversions';

  @override
  String get add_unit_conversion => 'Add Unit Conversion';

  @override
  String get edit_unit_conversion => 'Edit Unit Conversion';

  @override
  String get delete_unit_conversion => 'Delete Unit Conversion';

  @override
  String get unit_conversion_delete_confirm =>
      'Are you sure you want to delete this unit conversion? This action cannot be undone.';

  @override
  String get unit_conversion_deleted => 'Unit conversion deleted successfully.';

  @override
  String get no_unit_conversions => 'No unit conversions found.';

  @override
  String get from_unit => 'From Unit';

  @override
  String get to_unit => 'To Unit';

  @override
  String get deleteStockMovementAuthMessage =>
      'Please authenticate to delete this Stock Movement';

  @override
  String get confirmDeleteStockMovement =>
      'Are you sure you want to delete this stock movement? This action cannot be undone.';

  @override
  String get stockMovementDeleted => 'Stock movement deleted successfully.';

  @override
  String get errorDeletingStockMovement => 'Error deleting stock movement.';

  @override
  String get unitCostWithAdditional => 'Unit Cost (with additional cost)';

  @override
  String get stockMovementReports => 'Stock Movement Reports';

  @override
  String get stockMovementReportsDesc =>
      'View and analyze all stock in/out/transfer movements with filters and summaries.';

  @override
  String get totalIn => 'Total In';

  @override
  String get totalOut => 'Total Out';

  @override
  String get netMovement => 'Net Movement';

  @override
  String get manageDatabaseBackups => 'Manage Database Backups';

  @override
  String get backupDescription =>
      'Create online and local backups of your database, or restore data when needed.';

  @override
  String get enterYourCurrentAndNewPassword =>
      'Please enter your current password and choose a new one.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get actions => 'Actions';

  @override
  String get newSale => 'New Sale';

  @override
  String get unitName => 'Unit Name';

  @override
  String get fromUnit => 'From Unit';

  @override
  String get toUnit => 'To Unit';

  @override
  String get bill => 'Bill of';

  @override
  String get stockValueReports => 'Stock Value Reports';

  @override
  String get stockValueReportsDesc =>
      'View current stock values with pricing and summaries';

  @override
  String get detailed => 'Detailed';

  @override
  String get byWarehouse => 'By Warehouse';

  @override
  String get byProduct => 'By Product';

  @override
  String get byCurrency => 'By Currency';

  @override
  String get expiryDateFrom => 'Expiry Date From';

  @override
  String get expiryDateTo => 'Expiry Date To';

  @override
  String errorLoadingData(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String get totalValue => 'Total Value';

  @override
  String get totalQuantity => 'Total Quantity';

  @override
  String get stockValueByCurrency => 'Stock Value by Currency';

  @override
  String get stockValue => 'Stock Value';

  @override
  String get allProducts => 'All products';

  @override
  String get na => 'N/A';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get totalWarehouses => 'Total Warehouses';

  @override
  String get aboutDescription =>
      'Vetra is a leading technology company specializing in innovative business solutions and digital transformation. We empower businesses with cutting-edge technology to drive growth and success in the digital age.';

  @override
  String get companyTagline => 'Empowering Business Through Technology';

  @override
  String get followUs => 'Follow Us';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get companyAddress => 'Kabul, Afghanistan';

  @override
  String get allRightsReserved => 'All Rights Reserved';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpDescription =>
      'Need assistance? Contact our support team for help with Vetra.';

  @override
  String get financialBalance => 'Financial Balance';

  @override
  String get financialBalanceDesc =>
      'View account balances and identify payables/receivables';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get totalReceivable => 'Total Receivable';

  @override
  String get payableToOthers => 'You owe to others';

  @override
  String get receivableFromOthers => 'Others owe to you';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get positiveBalance => 'Positive Balance';

  @override
  String get negativeBalance => 'Negative Balance';

  @override
  String get zeroBalance => 'Zero Balance';

  @override
  String get balanceStatus => 'Balance Status';

  @override
  String get lastTransaction => 'Last Transaction';

  @override
  String get noTransactions => 'No transactions found';

  @override
  String shareTransactionGreeting(String accountName) {
    return 'Dear $accountName';
  }

  @override
  String shareTransactionMessage(
      String amount, String currency, String transactionType, String date) {
    return 'An amount of $amount $currency has been $transactionType to your account on $date.';
  }

  @override
  String get shareTransactionBalanceHeader => 'Current account balance:';

  @override
  String shareTransactionDescription(String description) {
    return 'Description: $description';
  }

  @override
  String shareTransactionSignature(String companyName) {
    return 'Sincerely,\n$companyName';
  }

  @override
  String get creditTransactionType => 'credited';

  @override
  String get debitTransactionType => 'debited';

  @override
  String get filterByAccountType => 'Filter by Account Type';

  @override
  String get filterByCurrency => 'Filter by Currency';

  @override
  String get showAll => 'Show All';

  @override
  String get noFinancialDataAvailable => 'No Financial Data Available';

  @override
  String get addAccountsTransactionsMessage =>
      'Add some accounts and transactions to see your financial balance';

  @override
  String get clearCacheRefresh => 'Clear Cache & Refresh';

  @override
  String get processingAccounts => 'Processing accounts...';

  @override
  String get batchProcessing => 'Batch processing for better performance';

  @override
  String get receivable => 'Receivable';

  @override
  String get payable => 'Payable';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get sortByTotalDesc => 'Total (High to Low)';

  @override
  String get sortByNameAsc => 'Name (A to Z)';

  @override
  String get sortByNameDesc => 'Name (Z to A)';

  @override
  String get sortByQuantityDesc => 'Quantity (High to Low)';

  @override
  String get send => 'Send';

  @override
  String get copy => 'Copy';
}
