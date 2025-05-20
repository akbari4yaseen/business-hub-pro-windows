import 'package:flutter/foundation.dart';
import '../utils/transaction_helper.dart';
import '../database/account_db.dart';

class AccountProvider with ChangeNotifier {
  final AccountDBHelper _db = AccountDBHelper();
  // Store accounts with their balances
  final Map<int, Map<String, dynamic>> _accountsCache = {};

  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get accounts => _accounts;
  bool get isLoading => _isLoading;

  // Get all customer accounts
  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _db.getOptionAccounts();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize provider
  Future<void> initialize() async {
    await loadAccounts();
  }

  // Get a cached account by ID
  Map<String, dynamic>? getAccount(int id) {
    return _accountsCache[id];
  }

  // Update account in cache and database
  Future<void> updateAccount(Map<String, dynamic> account) async {
    final accountId = account['id'] as int;

    // Update in database
    await AccountDBHelper().updateAccount(accountId, account);

    // Fetch fresh account data with new balances
    final refreshedAccount = await AccountDBHelper().getAccountById(accountId);

    if (refreshedAccount != null) {
      // Get transactions to calculate balances
      final transactions =
          await AccountDBHelper().getTransactionsForPrint(accountId);
      final balances = aggregateTransactions(transactions);

      // Add balances to the account data
      refreshedAccount['balances'] = balances;

      // Update in cache
      _accountsCache[accountId] = refreshedAccount;

      // Notify listeners to update UI
      notifyListeners();
    }
  }

  // Filter accounts by type
  List<Map<String, dynamic>> getAccountsByType(String type) {
    return _accounts
        .where((account) => account['account_type'] == type)
        .toList();
  }

  // Get customers (for invoices)
  List<Map<String, dynamic>> get customers {
    return getAccountsByType('customer');
  }
}
