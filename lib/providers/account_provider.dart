import 'package:flutter/foundation.dart';
import '../database/account_db.dart';

class AccountProvider with ChangeNotifier {
  final AccountDBHelper _db = AccountDBHelper();
  
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
  
  // Filter accounts by type
  List<Map<String, dynamic>> getAccountsByType(String type) {
    return _accounts.where((account) => account['account_type'] == type).toList();
  }
  
  // Get customers (for invoices)
  List<Map<String, dynamic>> get customers {
    return getAccountsByType('customer');
  }
} 