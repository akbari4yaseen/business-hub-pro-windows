import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ps.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('ps')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BusinessHub Pro'**
  String get appTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFarsi.
  ///
  /// In en, this message translates to:
  /// **'Farsi'**
  String get languageFarsi;

  /// No description provided for @languagePashto.
  ///
  /// In en, this message translates to:
  /// **'Pashto'**
  String get languagePashto;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// No description provided for @accountsPrint.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsPrint;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPassword;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get addAccount;

  /// No description provided for @addJournal.
  ///
  /// In en, this message translates to:
  /// **'New Journal'**
  String get addJournal;

  /// No description provided for @editJournal.
  ///
  /// In en, this message translates to:
  /// **'Edit Journal'**
  String get editJournal;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @exchanger.
  ///
  /// In en, this message translates to:
  /// **'Exchanger'**
  String get exchanger;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Unable to place call'**
  String get callError;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required!'**
  String get nameRequired;

  /// No description provided for @treasure.
  ///
  /// In en, this message translates to:
  /// **'Treasure'**
  String get treasure;

  /// No description provided for @noTreasure.
  ///
  /// In en, this message translates to:
  /// **'No Treasure'**
  String get noTreasure;

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @activeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Active Accounts'**
  String get activeAccounts;

  /// No description provided for @deactivatedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Deactivated Accounts'**
  String get deactivatedAccounts;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Account Transactions'**
  String get transactions;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @reactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Reactivate Account'**
  String get reactivateAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deactivation'**
  String get confirmDeactivate;

  /// No description provided for @confirmReactivate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reactivation'**
  String get confirmReactivate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @shareBalance.
  ///
  /// In en, this message translates to:
  /// **'Share Balance'**
  String get shareBalance;

  /// No description provided for @sendBalance.
  ///
  /// In en, this message translates to:
  /// **'Send Balance'**
  String get sendBalance;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid Phone Number'**
  String get invalidPhone;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Error in saving data'**
  String get saveError;

  /// No description provided for @existsAccountError.
  ///
  /// In en, this message translates to:
  /// **'An account with this name already exists'**
  String get existsAccountError;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectTrack.
  ///
  /// In en, this message translates to:
  /// **'Select Track'**
  String get selectTrack;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credited.
  ///
  /// In en, this message translates to:
  /// **'Credited'**
  String get credited;

  /// No description provided for @debited.
  ///
  /// In en, this message translates to:
  /// **'Debited'**
  String get debited;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @typeToSearchTrack.
  ///
  /// In en, this message translates to:
  /// **'Type to search track'**
  String get typeToSearchTrack;

  /// No description provided for @pleaseSelectTrack.
  ///
  /// In en, this message translates to:
  /// **'Please select a track'**
  String get pleaseSelectTrack;

  /// No description provided for @pleaseSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get pleaseSelectAccount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @searchJournal.
  ///
  /// In en, this message translates to:
  /// **'Search journals...'**
  String get searchJournal;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {accountName}?'**
  String deleteAccountConfirm(Object accountName);

  /// No description provided for @deactivateAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate account {accountName}?'**
  String deactivateAccountConfirm(Object accountName);

  /// No description provided for @reactivateAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reactivate account {accountName}?'**
  String reactivateAccountConfirm(Object accountName);

  /// No description provided for @noAccountsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get noAccountsAvailable;

  /// No description provided for @noMoreAccounts.
  ///
  /// In en, this message translates to:
  /// **'No more accounts'**
  String get noMoreAccounts;

  /// No description provided for @searchAccount.
  ///
  /// In en, this message translates to:
  /// **'Search accounts...'**
  String get searchAccount;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @incorrectCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get incorrectCurrentPassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @loginHeader.
  ///
  /// In en, this message translates to:
  /// **'Login to the system'**
  String get loginHeader;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get enterPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BusinessHubPro'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Database'**
  String get backupTitle;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @exportCanceledNoDirectory.
  ///
  /// In en, this message translates to:
  /// **'Export canceled. No directory selected.'**
  String get exportCanceledNoDirectory;

  /// No description provided for @databaseExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Database exported successfully to:\n{path}'**
  String databaseExportedSuccessfully(Object path);

  /// No description provided for @databaseFileNotFoundOrExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Database file not found or export failed!'**
  String get databaseFileNotFoundOrExportFailed;

  /// No description provided for @errorExportingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Error exporting database: {error}'**
  String errorExportingDatabase(Object error);

  /// No description provided for @restoreCanceledNoFile.
  ///
  /// In en, this message translates to:
  /// **'Restore canceled. No file selected.'**
  String get restoreCanceledNoFile;

  /// No description provided for @databaseRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Database restored successfully! Please restart the app.'**
  String get databaseRestoredSuccessfully;

  /// No description provided for @restoreFailedFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Restore failed! File not found or error occurred.'**
  String get restoreFailedFileNotFound;

  /// No description provided for @errorRestoringDatabase.
  ///
  /// In en, this message translates to:
  /// **'Error restoring database: {error}'**
  String errorRestoringDatabase(Object error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get companyInfo;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String themeMode(Object mode);

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @maxBalance.
  ///
  /// In en, this message translates to:
  /// **'Max Balance'**
  String get maxBalance;

  /// No description provided for @positiveNegativeBalances.
  ///
  /// In en, this message translates to:
  /// **'Positive / Negative Balances'**
  String get positiveNegativeBalances;

  /// No description provided for @showPositiveBalances.
  ///
  /// In en, this message translates to:
  /// **'Show Positive Balances'**
  String get showPositiveBalances;

  /// No description provided for @showNegativeBalances.
  ///
  /// In en, this message translates to:
  /// **'Show Negative Balances'**
  String get showNegativeBalances;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @defaultTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Default Transaction Type'**
  String get defaultTransactionType;

  /// No description provided for @defaultTrack.
  ///
  /// In en, this message translates to:
  /// **'Default Track'**
  String get defaultTrack;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @companyInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company information updated successfully'**
  String get companyInfoUpdated;

  /// No description provided for @companyInfoUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update company information'**
  String get companyInfoUpdateError;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @confirmDeleteJournal.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this journal entry? This action cannot be undone.'**
  String get confirmDeleteJournal;

  /// No description provided for @journalDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get journalDetails;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No Description'**
  String get noDescription;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @printDisabled.
  ///
  /// In en, this message translates to:
  /// **'Print (Disabled)'**
  String get printDisabled;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @noJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'No journal entries found.'**
  String get noJournalEntries;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @accountFilters.
  ///
  /// In en, this message translates to:
  /// **'Account Filters'**
  String get accountFilters;

  /// No description provided for @balanceRange.
  ///
  /// In en, this message translates to:
  /// **'Balance Range'**
  String get balanceRange;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @balanceType.
  ///
  /// In en, this message translates to:
  /// **'Balance Type'**
  String get balanceType;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max Amount'**
  String get maxAmount;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min Amount'**
  String get minAmount;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @errorDeletingJournal.
  ///
  /// In en, this message translates to:
  /// **'Error deleting journal. Please try again.'**
  String get errorDeletingJournal;

  /// No description provided for @errorLoadingJournal.
  ///
  /// In en, this message translates to:
  /// **'Error loading journal entries. Please try again.'**
  String get errorLoadingJournal;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to back up.'**
  String get storagePermissionRequired;

  /// No description provided for @shareMessageHeader.
  ///
  /// In en, this message translates to:
  /// **'📢 Dear *{name}*,\n\nHere is the detailed summary of your account balances across all available currencies. This report reflects the most recent transactions recorded in our system.\n\nPlease review the balances below carefully to stay updated and avoid any potential discrepancies.\n\n*Balances:*'**
  String shareMessageHeader(Object name);

  /// No description provided for @shareMessageTimestamp.
  ///
  /// In en, this message translates to:
  /// **'*Timestamp:* {date}'**
  String shareMessageTimestamp(Object date);

  /// No description provided for @shareMessageFooter.
  ///
  /// In en, this message translates to:
  /// **'---------------\n{appName}'**
  String shareMessageFooter(Object appName);

  /// No description provided for @shareMessagePaymentReminder.
  ///
  /// In en, this message translates to:
  /// **'💡 *Please pay the remaining balance.*'**
  String get shareMessagePaymentReminder;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading account stats'**
  String get statsLoadError;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allAccounts;

  /// No description provided for @activeAccountsShort.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeAccountsShort;

  /// No description provided for @deactivatedAccountsShort.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get deactivatedAccountsShort;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransaction;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactionsFound;

  /// No description provided for @noExchangesFound.
  ///
  /// In en, this message translates to:
  /// **'No exchanges found'**
  String get noExchangesFound;

  /// No description provided for @transactionEditError.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit Transaction'**
  String get transactionEditError;

  /// No description provided for @transactionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Journal transaction not found'**
  String get transactionNotFound;

  /// No description provided for @transactionDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete Transaction'**
  String get transactionDeleteError;

  /// No description provided for @onlineBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Online backup successful'**
  String get onlineBackupSuccess;

  /// No description provided for @onlineBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Online backup failed'**
  String get onlineBackupFailed;

  /// No description provided for @localBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local backup successful'**
  String get localBackupSuccess;

  /// No description provided for @localBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Local backup failed'**
  String get localBackupFailed;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;

  /// No description provided for @restoreOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite existing data. Continue?'**
  String get restoreOverwriteWarning;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database restored successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Database restore failed'**
  String get restoreFailed;

  /// No description provided for @databaseSettings.
  ///
  /// In en, this message translates to:
  /// **'Database Settings'**
  String get databaseSettings;

  /// No description provided for @baseUnit.
  ///
  /// In en, this message translates to:
  /// **'Base Unit'**
  String get baseUnit;

  /// No description provided for @lastOnlineBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Online Backup'**
  String get lastOnlineBackup;

  /// No description provided for @lastOfflineBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Offline Backup'**
  String get lastOfflineBackup;

  /// No description provided for @backupOnline.
  ///
  /// In en, this message translates to:
  /// **'Backup Online'**
  String get backupOnline;

  /// No description provided for @backupLocal.
  ///
  /// In en, this message translates to:
  /// **'Backup Local'**
  String get backupLocal;

  /// No description provided for @restoreDatabase.
  ///
  /// In en, this message translates to:
  /// **'Restore Database'**
  String get restoreDatabase;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @systemAccount.
  ///
  /// In en, this message translates to:
  /// **'System Account'**
  String get systemAccount;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noSystemAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No system accounts found.'**
  String get noSystemAccountsFound;

  /// No description provided for @currencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get currencies;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvailable;

  /// No description provided for @accountReports.
  ///
  /// In en, this message translates to:
  /// **'Account Reports'**
  String get accountReports;

  /// No description provided for @accountReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Account balances, and more'**
  String get accountReportsDesc;

  /// No description provided for @dailyBalancesDesc.
  ///
  /// In en, this message translates to:
  /// **'Line chart showing daily account balances'**
  String get dailyBalancesDesc;

  /// No description provided for @systemAccountReports.
  ///
  /// In en, this message translates to:
  /// **'System Account Reports'**
  String get systemAccountReports;

  /// No description provided for @systemAccountReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'List of system accounts and balances'**
  String get systemAccountReportsDesc;

  /// No description provided for @moreVisualizations.
  ///
  /// In en, this message translates to:
  /// **'More Visualizations'**
  String get moreVisualizations;

  /// No description provided for @moreVisualizationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Future charts and analytics will appear here'**
  String get moreVisualizationsDesc;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentLabel;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get periodMonth;

  /// No description provided for @period3Months.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get period3Months;

  /// No description provided for @period6Months.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get period6Months;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get periodYear;

  /// No description provided for @period3Years.
  ///
  /// In en, this message translates to:
  /// **'3Y'**
  String get period3Years;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @metricCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get metricCurrentBalance;

  /// No description provided for @metricChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get metricChange;

  /// No description provided for @dailyBalances.
  ///
  /// In en, this message translates to:
  /// **'Daily Balances'**
  String get dailyBalances;

  /// No description provided for @accountBalances.
  ///
  /// In en, this message translates to:
  /// **'Account Balances'**
  String get accountBalances;

  /// No description provided for @accountsByType.
  ///
  /// In en, this message translates to:
  /// **'Accounts by Type'**
  String get accountsByType;

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance ({currency})'**
  String balanceLabel(Object currency);

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCount(Object count);

  /// No description provided for @printed.
  ///
  /// In en, this message translates to:
  /// **'Printed: {date}'**
  String printed(Object date);

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(Object page, Object total);

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get number;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reminder?'**
  String get deleteReminderConfirmation;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet!'**
  String get noRemindersYet;

  /// No description provided for @newReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminderTitle;

  /// No description provided for @editReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminderTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @dateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTimeLabel;

  /// No description provided for @repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatLabel;

  /// No description provided for @intervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get intervalLabel;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @defaultReminder.
  ///
  /// In en, this message translates to:
  /// **'Time for your reminder!'**
  String get defaultReminder;

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeats;

  /// No description provided for @titleEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleEmptyError;

  /// No description provided for @pickDateTimeError.
  ///
  /// In en, this message translates to:
  /// **'Please pick date & time'**
  String get pickDateTimeError;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllReadTooltip;

  /// No description provided for @clearAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllTooltip;

  /// No description provided for @clearAllNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotificationsTitle;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @clearAllNotificationsContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all notifications?'**
  String get clearAllNotificationsContent;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get useFingerprint;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to access BusinessHubPro'**
  String get biometricReason;

  /// No description provided for @biometricError.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricError;

  /// No description provided for @backupCardFriendlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe! Remember to back up regularly.'**
  String get backupCardFriendlyMessage;

  /// Label for how many days ago something happened
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} one{{count} day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @enterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordError;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authTitle;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricFailed;

  /// No description provided for @deleteAccountAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting an Account requires authentication'**
  String get deleteAccountAuthMessage;

  /// No description provided for @deleteJournalAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to delete this Journal'**
  String get deleteJournalAuthMessage;

  /// No description provided for @confirmDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to delete this Transaction'**
  String get confirmDeleteTransaction;

  /// No description provided for @journalSaved.
  ///
  /// In en, this message translates to:
  /// **'Journal saved'**
  String get journalSaved;

  /// No description provided for @errorSavingJournal.
  ///
  /// In en, this message translates to:
  /// **'Error saving Journal'**
  String get errorSavingJournal;

  /// No description provided for @printSettings.
  ///
  /// In en, this message translates to:
  /// **'Print Settings'**
  String get printSettings;

  /// No description provided for @preparingPrint.
  ///
  /// In en, this message translates to:
  /// **'Preparing print...'**
  String get preparingPrint;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Dear {accountName},\n\nYour account has been {action} with {amount} {currency} on {date}.\n\nExtra Description: {description}\n\n{footer}'**
  String shareMessage(Object accountName, Object action, Object amount,
      Object currency, Object date, Object description, Object footer);

  /// No description provided for @onlineBackupOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Backup Overdue'**
  String get onlineBackupOverdueTitle;

  /// No description provided for @onlineBackupOverdueMessage.
  ///
  /// In en, this message translates to:
  /// **'Your last online backup was more than 7 days ago. Please back up your data online.'**
  String get onlineBackupOverdueMessage;

  /// No description provided for @offlineBackupOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Backup Overdue'**
  String get offlineBackupOverdueTitle;

  /// No description provided for @offlineBackupOverdueMessage.
  ///
  /// In en, this message translates to:
  /// **'Your last offline backup was more than 7 days ago. Please back up your data locally.'**
  String get offlineBackupOverdueMessage;

  /// No description provided for @accountInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'The account \"{name}\" is inactive'**
  String accountInactiveTitle(Object name);

  /// No description provided for @accountInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'The account \"{name}\" has had no transactions in the last {days} days.'**
  String accountInactiveMessage(Object days, Object name);

  /// No description provided for @inactivityDays.
  ///
  /// In en, this message translates to:
  /// **'The number of days an account has no transaction'**
  String get inactivityDays;

  /// No description provided for @periodicReports.
  ///
  /// In en, this message translates to:
  /// **'Periodic Reports'**
  String get periodicReports;

  /// No description provided for @periodicReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View credit/debit balances over time'**
  String get periodicReportsDesc;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last14Days.
  ///
  /// In en, this message translates to:
  /// **'Last 14 Days'**
  String get last14Days;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get last6Months;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get totalCredit;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get totalDebit;

  /// No description provided for @pleaseSelectAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Please select all filters'**
  String get pleaseSelectAllFilters;

  /// No description provided for @pleaseSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Please select date range'**
  String get pleaseSelectDateRange;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @invoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get invoiceDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDue;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @soldGoodsNotReturnable.
  ///
  /// In en, this message translates to:
  /// **'Sold goods are not returnable'**
  String get soldGoodsNotReturnable;

  /// No description provided for @sells.
  ///
  /// In en, this message translates to:
  /// **'Sells'**
  String get sells;

  /// No description provided for @inventoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventoryManagement;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @warehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get warehouses;

  /// No description provided for @stockMovements.
  ///
  /// In en, this message translates to:
  /// **'Stock Movements'**
  String get stockMovements;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @allInvoices.
  ///
  /// In en, this message translates to:
  /// **'All Invoices'**
  String get allInvoices;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @failedRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment: {error}'**
  String failedRecordPayment(Object error);

  /// No description provided for @failedFinalizeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to finalize invoice: {error}'**
  String failedFinalizeInvoice(Object error);

  /// No description provided for @confirmFinalizeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Confirm Invoice Finalization'**
  String get confirmFinalizeInvoice;

  /// No description provided for @finalizeInvoiceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finalize this invoice? This action cannot be undone.'**
  String get finalizeInvoiceConfirmation;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get noInvoices;

  /// No description provided for @noOverdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'No overdue invoices'**
  String get noOverdueInvoices;

  /// No description provided for @customerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String customerInvoice(Object name);

  /// No description provided for @dateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateInvoice(Object date);

  /// No description provided for @dueInvoice.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueInvoice(Object date);

  /// No description provided for @totalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalInvoice(Object amount);

  /// No description provided for @paidInvoice.
  ///
  /// In en, this message translates to:
  /// **'Paid: {amount}'**
  String paidInvoice(Object amount);

  /// No description provided for @balanceInvoice.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceInvoice(Object amount);

  /// No description provided for @overdueByInvoice.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String overdueByInvoice(Object days);

  /// No description provided for @finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get finalize;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @editInvoice.
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice'**
  String get editInvoice;

  /// No description provided for @deleteInvoice.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoice;

  /// No description provided for @printInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get printInvoice;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @deleteInvoiceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this invoice?'**
  String get deleteInvoiceConfirmation;

  /// No description provided for @invoiceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Invoice deleted successfully'**
  String get invoiceDeleted;

  /// No description provided for @errorDeletingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Error deleting invoice'**
  String get errorDeletingInvoice;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @invoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceLabel;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @pleaseEnterPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter payment amount'**
  String get pleaseEnterPaymentAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get amountGreaterThanZero;

  /// No description provided for @amountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed outstanding balance'**
  String get amountExceedsBalance;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @invoiceNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Invoice number is required'**
  String get invoiceNumberRequired;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required'**
  String get customerNameRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than 0'**
  String get invalidAmount;

  /// No description provided for @invoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved successfully'**
  String get invoiceSaved;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @noItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'No items added yet. Press \"Add Item\" to begin.'**
  String get noItemsAdded;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found. Please add a customer account first.'**
  String get noCustomersFound;

  /// No description provided for @customerAccount.
  ///
  /// In en, this message translates to:
  /// **'Customer Account'**
  String get customerAccount;

  /// No description provided for @pleaseSelectProductForAllItems.
  ///
  /// In en, this message translates to:
  /// **'Please select a product for all items'**
  String get pleaseSelectProductForAllItems;

  /// No description provided for @quantityMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0 for all items'**
  String get quantityMustBeGreaterThanZero;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get updating;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating'**
  String get creating;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available. Please add products first.'**
  String get noProductsAvailable;

  /// No description provided for @warningNoStockFor.
  ///
  /// In en, this message translates to:
  /// **'Warning: No stock available for'**
  String warningNoStockFor(Object product);

  /// No description provided for @availableStock.
  ///
  /// In en, this message translates to:
  /// **'Available Stock'**
  String get availableStock;

  /// No description provided for @noStockAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stock available'**
  String get noStockAvailable;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @notEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock'**
  String get notEnoughStock;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get invalidQuantity;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProduct;

  /// No description provided for @invoiceStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get invoiceStatusDraft;

  /// No description provided for @invoiceStatusFinalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get invoiceStatusFinalized;

  /// No description provided for @invoiceStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get invoiceStatusPartiallyPaid;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoiceStatusCancelled;

  /// No description provided for @preSale.
  ///
  /// In en, this message translates to:
  /// **'Pre-Sale'**
  String get preSale;

  /// No description provided for @isPreSale.
  ///
  /// In en, this message translates to:
  /// **'Is Pre-Sale'**
  String get isPreSale;

  /// No description provided for @preSaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Pre-sale invoices allow selling products without checking stock availability'**
  String get preSaleDescription;

  /// No description provided for @preSaleWarning.
  ///
  /// In en, this message translates to:
  /// **'e-sale mode: Stock availability will not be checked'**
  String get preSaleWarning;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get activeFilters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @lowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStockAlerts;

  /// No description provided for @expiringProducts.
  ///
  /// In en, this message translates to:
  /// **'Expiring Products'**
  String get expiringProducts;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @allWarehouses.
  ///
  /// In en, this message translates to:
  /// **'All Warehouses'**
  String get allWarehouses;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @minimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock'**
  String get minimumStock;

  /// No description provided for @maximumStock.
  ///
  /// In en, this message translates to:
  /// **'Maximum Stock'**
  String get maximumStock;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @lastMovement.
  ///
  /// In en, this message translates to:
  /// **'Last Movement'**
  String get lastMovement;

  /// No description provided for @moveStock.
  ///
  /// In en, this message translates to:
  /// **'Move Stock'**
  String get moveStock;

  /// No description provided for @adjustQuantity.
  ///
  /// In en, this message translates to:
  /// **'Adjust Quantity'**
  String get adjustQuantity;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @refreshProducts.
  ///
  /// In en, this message translates to:
  /// **'Refresh Products'**
  String get refreshProducts;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get showInactive;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @changeSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search criteria'**
  String get changeSearchCriteria;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {productName}?'**
  String deleteConfirm(Object productName);

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @activatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product activated successfully'**
  String get activatedSuccess;

  /// No description provided for @deactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deactivated successfully'**
  String get deactivatedSuccess;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @stockSettings.
  ///
  /// In en, this message translates to:
  /// **'Stock Settings'**
  String get stockSettings;

  /// No description provided for @minStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get minStock;

  /// No description provided for @maxStock.
  ///
  /// In en, this message translates to:
  /// **'Max Stock'**
  String get maxStock;

  /// No description provided for @reorderPoint.
  ///
  /// In en, this message translates to:
  /// **'Reorder Point'**
  String get reorderPoint;

  /// No description provided for @search_warehouses.
  ///
  /// In en, this message translates to:
  /// **'Search Warehouses'**
  String get search_warehouses;

  /// No description provided for @show_empty.
  ///
  /// In en, this message translates to:
  /// **'Show Empty'**
  String get show_empty;

  /// No description provided for @refresh_warehouses.
  ///
  /// In en, this message translates to:
  /// **'Refresh Warehouses'**
  String get refresh_warehouses;

  /// No description provided for @no_warehouses_found.
  ///
  /// In en, this message translates to:
  /// **'No warehouses found'**
  String get no_warehouses_found;

  /// No description provided for @clear_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clear_filters;

  /// No description provided for @edit_warehouse.
  ///
  /// In en, this message translates to:
  /// **'Edit Warehouse'**
  String get edit_warehouse;

  /// No description provided for @delete_warehouse.
  ///
  /// In en, this message translates to:
  /// **'Delete Warehouse'**
  String get delete_warehouse;

  /// No description provided for @delete_warehouse_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the warehouse \"{name}\"?'**
  String delete_warehouse_confirm(Object name);

  /// No description provided for @warehouse_deleted.
  ///
  /// In en, this message translates to:
  /// **'Warehouse deleted successfully'**
  String get warehouse_deleted;

  /// No description provided for @no_items_in_warehouse.
  ///
  /// In en, this message translates to:
  /// **'No items in this warehouse'**
  String get no_items_in_warehouse;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @noMovementsFound.
  ///
  /// In en, this message translates to:
  /// **'No movements found'**
  String get noMovementsFound;

  /// No description provided for @movementType.
  ///
  /// In en, this message translates to:
  /// **'Movement Type'**
  String get movementType;

  /// No description provided for @movementType_purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get movementType_purchase;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @movementType_sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get movementType_sale;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @movementDetails.
  ///
  /// In en, this message translates to:
  /// **'Movement Details'**
  String get movementDetails;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @productActivated.
  ///
  /// In en, this message translates to:
  /// **'Product activated successfully'**
  String get productActivated;

  /// No description provided for @productDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Product deactivated successfully'**
  String get productDeactivated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeleted;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {productName}?'**
  String confirmDeleteProduct(Object productName);

  /// No description provided for @movementType_stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get movementType_stockIn;

  /// No description provided for @movementType_stockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock Out'**
  String get movementType_stockOut;

  /// No description provided for @movementType_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get movementType_transfer;

  /// No description provided for @movementType_adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get movementType_adjustment;

  /// No description provided for @add_unit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get add_unit;

  /// No description provided for @edit_unit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get edit_unit;

  /// No description provided for @unit_name.
  ///
  /// In en, this message translates to:
  /// **'Unit Name'**
  String get unit_name;

  /// No description provided for @unit_symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol (Optional)'**
  String get unit_symbol;

  /// No description provided for @unit_description.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get unit_description;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete_unit.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit'**
  String get delete_unit;

  /// No description provided for @unit_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{unit}\"? This action cannot be undone.'**
  String unit_delete_confirm(Object unit);

  /// No description provided for @no_units.
  ///
  /// In en, this message translates to:
  /// **'No units found. Add your first unit.'**
  String get no_units;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Add your first category.'**
  String get noCategoriesFound;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String confirmDeleteCategory(Object name);

  /// No description provided for @newStockMovement.
  ///
  /// In en, this message translates to:
  /// **'New Stock Movement'**
  String get newStockMovement;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get selectProduct;

  /// No description provided for @sourceWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Source Warehouse'**
  String get sourceWarehouse;

  /// No description provided for @selectSourceWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Please select a source warehouse'**
  String get selectSourceWarehouse;

  /// No description provided for @destinationWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Destination Warehouse'**
  String get destinationWarehouse;

  /// No description provided for @selectDestinationWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination warehouse'**
  String get selectDestinationWarehouse;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get enterQuantity;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @errorRecordingMovement.
  ///
  /// In en, this message translates to:
  /// **'Error recording stock movement'**
  String get errorRecordingMovement;

  /// No description provided for @addNewWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Add New Warehouse'**
  String get addNewWarehouse;

  /// No description provided for @warehouseName.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Name'**
  String get warehouseName;

  /// No description provided for @enterWarehouseName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a warehouse name'**
  String get enterWarehouseName;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get enterAddress;

  /// No description provided for @errorCreatingWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Error creating warehouse: {error}'**
  String errorCreatingWarehouse(Object error);

  /// No description provided for @editWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Edit Warehouse'**
  String get editWarehouse;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterName;

  /// No description provided for @enterWarehouseDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter warehouse description (optional)'**
  String get enterWarehouseDescriptionOptional;

  /// No description provided for @pleaseSelectWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Please select a warehouse'**
  String get pleaseSelectWarehouse;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get enterValidQuantity;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get pleaseEnterProductName;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Please select a unit'**
  String get pleaseSelectUnit;

  /// No description provided for @pleaseEnterMinimumStock.
  ///
  /// In en, this message translates to:
  /// **'Please enter minimum stock'**
  String get pleaseEnterMinimumStock;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @barcodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Barcode (Optional)'**
  String get barcodeOptional;

  /// No description provided for @hasExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Has Expiry Date'**
  String get hasExpiryDate;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully.'**
  String get categoryDeleted;

  /// No description provided for @paymentForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Payment for invoice'**
  String get paymentForInvoice;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @backupCanceledNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Backup Canceled. No Location'**
  String get backupCanceledNoLocation;

  /// No description provided for @selectBackupLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Backup Location'**
  String get selectBackupLocation;

  /// No description provided for @copyBalance.
  ///
  /// In en, this message translates to:
  /// **'Copy Balance'**
  String get copyBalance;

  /// No description provided for @balanceCopied.
  ///
  /// In en, this message translates to:
  /// **'Balance copied to clipboard'**
  String get balanceCopied;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdated;

  /// No description provided for @movementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Movement recorded'**
  String get movementRecorded;

  /// No description provided for @movementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Movement updated'**
  String get movementUpdated;

  /// No description provided for @editStockMovement.
  ///
  /// In en, this message translates to:
  /// **'Edit stock movement'**
  String get editStockMovement;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequired;

  /// No description provided for @unitRequired.
  ///
  /// In en, this message translates to:
  /// **'Unit is required'**
  String get unitRequired;

  /// No description provided for @minStockRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock is required'**
  String get minStockRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @reorderPointRequired.
  ///
  /// In en, this message translates to:
  /// **'Reorder point is required'**
  String get reorderPointRequired;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @isActive.
  ///
  /// In en, this message translates to:
  /// **'Is active'**
  String get isActive;

  /// No description provided for @cancelInvoice.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invoice'**
  String get cancelInvoice;

  /// No description provided for @cancelInvoiceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this invoice? This will revert stock and remove from account details.'**
  String get cancelInvoiceConfirmation;

  /// No description provided for @invoiceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invoice cancelled'**
  String get invoiceCancelled;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @newExchange.
  ///
  /// In en, this message translates to:
  /// **'New Exchange'**
  String get newExchange;

  /// No description provided for @editExchange.
  ///
  /// In en, this message translates to:
  /// **'Edit Exchange'**
  String get editExchange;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @addPurchase.
  ///
  /// In en, this message translates to:
  /// **'Add Purchase'**
  String get addPurchase;

  /// No description provided for @refreshPurchases.
  ///
  /// In en, this message translates to:
  /// **'Refresh Purchases'**
  String get refreshPurchases;

  /// No description provided for @searchPurchases.
  ///
  /// In en, this message translates to:
  /// **'Search purchases...'**
  String get searchPurchases;

  /// No description provided for @noPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No purchases found'**
  String get noPurchasesFound;

  /// No description provided for @purchaseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Purchase deleted successfully'**
  String get purchaseDeleted;

  /// No description provided for @deletePurchase.
  ///
  /// In en, this message translates to:
  /// **'Delete Purchase'**
  String get deletePurchase;

  /// No description provided for @deletePurchaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this purchase? This action cannot be undone.'**
  String get deletePurchaseConfirmation;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get referenceNumber;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @purchaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Purchase Details'**
  String get purchaseDetails;

  /// No description provided for @editPurchase.
  ///
  /// In en, this message translates to:
  /// **'Edit Purchase'**
  String get editPurchase;

  /// No description provided for @unit_conversion.
  ///
  /// In en, this message translates to:
  /// **'Unit Conversion'**
  String get unit_conversion;

  /// No description provided for @conversion_rate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversion_rate;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @noUnitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No units available for this product. Please add units first.'**
  String get noUnitsAvailable;

  /// No description provided for @manageUnits.
  ///
  /// In en, this message translates to:
  /// **'Manage Units'**
  String get manageUnits;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @setBaseUnit.
  ///
  /// In en, this message translates to:
  /// **'Set as Base Unit'**
  String get setBaseUnit;

  /// No description provided for @deleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit'**
  String get deleteUnit;

  /// No description provided for @noUnits.
  ///
  /// In en, this message translates to:
  /// **'No units defined. Add your first unit.'**
  String get noUnits;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInfo;

  /// No description provided for @divide.
  ///
  /// In en, this message translates to:
  /// **'Divide (/)'**
  String get divide;

  /// No description provided for @errorLoadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts: {e}'**
  String errorLoadingAccounts(Object e);

  /// No description provided for @errorLoadingExchangeData.
  ///
  /// In en, this message translates to:
  /// **'Error loading exchange data: {e}'**
  String errorLoadingExchangeData(Object e);

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(Object error);

  /// No description provided for @exchangeDetails.
  ///
  /// In en, this message translates to:
  /// **'Exchange Details'**
  String get exchangeDetails;

  /// No description provided for @expectedRateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expected Rate (Optional)'**
  String get expectedRateOptional;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get fromAccount;

  /// No description provided for @fromCurrency.
  ///
  /// In en, this message translates to:
  /// **'From Currency'**
  String get fromCurrency;

  /// No description provided for @multiply.
  ///
  /// In en, this message translates to:
  /// **'Multiply (*)'**
  String get multiply;

  /// No description provided for @selectBothAccounts.
  ///
  /// In en, this message translates to:
  /// **'Please select both accounts'**
  String get selectBothAccounts;

  /// No description provided for @resultAmount.
  ///
  /// In en, this message translates to:
  /// **'Result Amount'**
  String get resultAmount;

  /// No description provided for @saveExchange.
  ///
  /// In en, this message translates to:
  /// **'Save Exchange'**
  String get saveExchange;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get toAccount;

  /// No description provided for @toCurrency.
  ///
  /// In en, this message translates to:
  /// **'To Currency'**
  String get toCurrency;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit/Loss:'**
  String get profitLoss;

  /// No description provided for @errorRefreshingData.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing data'**
  String get errorRefreshingData;

  /// No description provided for @deleteExchangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Exchange'**
  String get deleteExchangeTitle;

  /// No description provided for @deleteExchangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this exchange?'**
  String get deleteExchangeConfirm;

  /// No description provided for @exchangeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Exchange deleted successfully'**
  String get exchangeDeleted;

  /// No description provided for @errorDeletingExchange.
  ///
  /// In en, this message translates to:
  /// **'Error deleting exchange'**
  String get errorDeletingExchange;

  /// No description provided for @additionalCost.
  ///
  /// In en, this message translates to:
  /// **'Additional Cost'**
  String get additionalCost;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @costPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Cost per Unit'**
  String get costPerUnit;

  /// No description provided for @purchaseReports.
  ///
  /// In en, this message translates to:
  /// **'Purchase Reports'**
  String get purchaseReports;

  /// No description provided for @purchaseReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and analyze all purchase transactions with filters and summaries.'**
  String get purchaseReportsDesc;

  /// No description provided for @totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total Purchases: {count}'**
  String totalPurchases(Object count);

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount: {amount}'**
  String totalAmount(Object amount);

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @salesReports.
  ///
  /// In en, this message translates to:
  /// **'Sales Reports'**
  String get salesReports;

  /// No description provided for @salesReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and analyze all sales transactions with filters and summaries.'**
  String get salesReportsDesc;

  /// No description provided for @totalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices: {count}'**
  String totalInvoices(Object count);

  /// No description provided for @totalIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Total is required'**
  String get totalIsRequired;

  /// No description provided for @totalMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Total must be positive'**
  String get totalMustBePositive;

  /// No description provided for @invalidTotalFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid total format'**
  String get invalidTotalFormat;

  /// No description provided for @adjustedUp.
  ///
  /// In en, this message translates to:
  /// **'Adjusted up by'**
  String get adjustedUp;

  /// No description provided for @adjustedDown.
  ///
  /// In en, this message translates to:
  /// **'Adjusted down by'**
  String get adjustedDown;

  /// No description provided for @manualTotalAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Manual total adjustment'**
  String get manualTotalAdjustment;

  /// No description provided for @calculatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Calculated total'**
  String get calculatedTotal;

  /// No description provided for @finalTotal.
  ///
  /// In en, this message translates to:
  /// **'Final total'**
  String get finalTotal;

  /// No description provided for @unit_conversion_management.
  ///
  /// In en, this message translates to:
  /// **'Unit Conversions'**
  String get unit_conversion_management;

  /// No description provided for @add_unit_conversion.
  ///
  /// In en, this message translates to:
  /// **'Add Unit Conversion'**
  String get add_unit_conversion;

  /// No description provided for @edit_unit_conversion.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit Conversion'**
  String get edit_unit_conversion;

  /// No description provided for @delete_unit_conversion.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit Conversion'**
  String get delete_unit_conversion;

  /// No description provided for @unit_conversion_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this unit conversion? This action cannot be undone.'**
  String get unit_conversion_delete_confirm;

  /// No description provided for @unit_conversion_deleted.
  ///
  /// In en, this message translates to:
  /// **'Unit conversion deleted successfully.'**
  String get unit_conversion_deleted;

  /// No description provided for @no_unit_conversions.
  ///
  /// In en, this message translates to:
  /// **'No unit conversions found.'**
  String get no_unit_conversions;

  /// No description provided for @from_unit.
  ///
  /// In en, this message translates to:
  /// **'From Unit'**
  String get from_unit;

  /// No description provided for @to_unit.
  ///
  /// In en, this message translates to:
  /// **'To Unit'**
  String get to_unit;

  /// No description provided for @deleteStockMovementAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to delete this Stock Movement'**
  String get deleteStockMovementAuthMessage;

  /// No description provided for @confirmDeleteStockMovement.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this stock movement? This action cannot be undone.'**
  String get confirmDeleteStockMovement;

  /// No description provided for @stockMovementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Stock movement deleted successfully.'**
  String get stockMovementDeleted;

  /// No description provided for @errorDeletingStockMovement.
  ///
  /// In en, this message translates to:
  /// **'Error deleting stock movement.'**
  String get errorDeletingStockMovement;

  /// No description provided for @unitCostWithAdditional.
  ///
  /// In en, this message translates to:
  /// **'Unit Cost (with additional cost)'**
  String get unitCostWithAdditional;

  /// No description provided for @stockMovementReports.
  ///
  /// In en, this message translates to:
  /// **'Stock Movement Reports'**
  String get stockMovementReports;

  /// No description provided for @stockMovementReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and analyze all stock in/out/transfer movements with filters and summaries.'**
  String get stockMovementReportsDesc;

  /// No description provided for @totalIn.
  ///
  /// In en, this message translates to:
  /// **'Total In'**
  String get totalIn;

  /// No description provided for @totalOut.
  ///
  /// In en, this message translates to:
  /// **'Total Out'**
  String get totalOut;

  /// No description provided for @netMovement.
  ///
  /// In en, this message translates to:
  /// **'Net Movement'**
  String get netMovement;

  /// No description provided for @manageDatabaseBackups.
  ///
  /// In en, this message translates to:
  /// **'Manage Database Backups'**
  String get manageDatabaseBackups;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create online and local backups of your database, or restore data when needed.'**
  String get backupDescription;

  /// No description provided for @enterYourCurrentAndNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password and choose a new one.'**
  String get enterYourCurrentAndNewPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit Name'**
  String get unitName;

  /// No description provided for @fromUnit.
  ///
  /// In en, this message translates to:
  /// **'From Unit'**
  String get fromUnit;

  /// No description provided for @toUnit.
  ///
  /// In en, this message translates to:
  /// **'To Unit'**
  String get toUnit;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill of'**
  String get bill;

  /// No description provided for @stockValueReports.
  ///
  /// In en, this message translates to:
  /// **'Stock Value Reports'**
  String get stockValueReports;

  /// No description provided for @stockValueReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View current stock values with pricing and summaries'**
  String get stockValueReportsDesc;

  /// No description provided for @detailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailed;

  /// No description provided for @byWarehouse.
  ///
  /// In en, this message translates to:
  /// **'By Warehouse'**
  String get byWarehouse;

  /// No description provided for @byProduct.
  ///
  /// In en, this message translates to:
  /// **'By Product'**
  String get byProduct;

  /// No description provided for @byCurrency.
  ///
  /// In en, this message translates to:
  /// **'By Currency'**
  String get byCurrency;

  /// No description provided for @expiryDateFrom.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date From'**
  String get expiryDateFrom;

  /// No description provided for @expiryDateTo.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date To'**
  String get expiryDateTo;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get totalQuantity;

  /// No description provided for @stockValueByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Stock Value by Currency'**
  String get stockValueByCurrency;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stockValue;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get allProducts;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Total Warehouses'**
  String get totalWarehouses;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Vetra is a leading technology company specializing in innovative business solutions and digital transformation. We empower businesses with cutting-edge technology to drive growth and success in the digital age.'**
  String get aboutDescription;

  /// No description provided for @companyTagline.
  ///
  /// In en, this message translates to:
  /// **'Empowering Business Through Technology'**
  String get companyTagline;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get followUs;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @companyAddress.
  ///
  /// In en, this message translates to:
  /// **'Kabul, Afghanistan'**
  String get companyAddress;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All Rights Reserved'**
  String get allRightsReserved;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Need assistance? Contact our support team for help with Vetra.'**
  String get helpDescription;

  /// No description provided for @financialBalance.
  ///
  /// In en, this message translates to:
  /// **'Financial Balance'**
  String get financialBalance;

  /// No description provided for @financialBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'View account balances and identify payables/receivables'**
  String get financialBalanceDesc;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @totalReceivable.
  ///
  /// In en, this message translates to:
  /// **'Total Receivable'**
  String get totalReceivable;

  /// No description provided for @payableToOthers.
  ///
  /// In en, this message translates to:
  /// **'You owe to others'**
  String get payableToOthers;

  /// No description provided for @receivableFromOthers.
  ///
  /// In en, this message translates to:
  /// **'Others owe to you'**
  String get receivableFromOthers;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @positiveBalance.
  ///
  /// In en, this message translates to:
  /// **'Positive Balance'**
  String get positiveBalance;

  /// No description provided for @negativeBalance.
  ///
  /// In en, this message translates to:
  /// **'Negative Balance'**
  String get negativeBalance;

  /// No description provided for @zeroBalance.
  ///
  /// In en, this message translates to:
  /// **'Zero Balance'**
  String get zeroBalance;

  /// No description provided for @balanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Balance Status'**
  String get balanceStatus;

  /// No description provided for @lastTransaction.
  ///
  /// In en, this message translates to:
  /// **'Last Transaction'**
  String get lastTransaction;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactions;

  /// Greeting for the transaction share message
  ///
  /// In en, this message translates to:
  /// **'Dear {accountName}'**
  String shareTransactionGreeting(String accountName);

  /// Main transaction message with amount, currency, type and date
  ///
  /// In en, this message translates to:
  /// **'An amount of {amount} {currency} has been {transactionType} to your account on {date}.'**
  String shareTransactionMessage(
      String amount, String currency, String transactionType, String date);

  /// No description provided for @shareTransactionBalanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Current account balance:'**
  String get shareTransactionBalanceHeader;

  /// Transaction description text
  ///
  /// In en, this message translates to:
  /// **'Description: {description}'**
  String shareTransactionDescription(String description);

  /// Signature with company name
  ///
  /// In en, this message translates to:
  /// **'Sincerely,\n{companyName}'**
  String shareTransactionSignature(String companyName);

  /// No description provided for @creditTransactionType.
  ///
  /// In en, this message translates to:
  /// **'credited'**
  String get creditTransactionType;

  /// No description provided for @debitTransactionType.
  ///
  /// In en, this message translates to:
  /// **'debited'**
  String get debitTransactionType;

  /// No description provided for @filterByAccountType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Account Type'**
  String get filterByAccountType;

  /// No description provided for @filterByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Filter by Currency'**
  String get filterByCurrency;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @noFinancialDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Financial Data Available'**
  String get noFinancialDataAvailable;

  /// No description provided for @addAccountsTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add some accounts and transactions to see your financial balance'**
  String get addAccountsTransactionsMessage;

  /// No description provided for @clearCacheRefresh.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache & Refresh'**
  String get clearCacheRefresh;

  /// No description provided for @processingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Processing accounts...'**
  String get processingAccounts;

  /// No description provided for @batchProcessing.
  ///
  /// In en, this message translates to:
  /// **'Batch processing for better performance'**
  String get batchProcessing;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get receivable;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payable;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @sortByTotalDesc.
  ///
  /// In en, this message translates to:
  /// **'Total (High to Low)'**
  String get sortByTotalDesc;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A to Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z to A)'**
  String get sortByNameDesc;

  /// No description provided for @sortByQuantityDesc.
  ///
  /// In en, this message translates to:
  /// **'Quantity (High to Low)'**
  String get sortByQuantityDesc;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'ps'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'ps':
      return AppLocalizationsPs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
