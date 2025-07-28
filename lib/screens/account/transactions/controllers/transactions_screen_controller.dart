import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../database/account_db.dart';
import '../../../../database/journal_db.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/transaction_helper.dart';

class TransactionsScreenController extends ChangeNotifier {
  static const int _pageSize = 30;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  // Data
  final List<Map<String, dynamic>> _transactions = [];
  final List<String> _currencyOptions = ['all'];
  Map<String, dynamic> _balances = {};

  // State
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;

  // Filters
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;

  // Account info
  final Map<String, dynamic> _account;

  // Getters
  List<Map<String, dynamic>> get transactions => _transactions;
  List<String> get currencyOptions => _currencyOptions;
  Map<String, dynamic> get balances => _balances;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  String? get selectedCurrency => _selectedCurrency;
  DateTime? get selectedDate => _selectedDate;
  Map<String, dynamic> get account => _account;
  NumberFormat get amountFormatter => _amountFormatter;

  TransactionsScreenController(this._account) {
    _balances = _account['balances'] as Map<String, dynamic>? ?? {};
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadCurrencies(),
      _refreshTransactions(),
    ]);
  }

  Future<void> _loadCurrencies() async {
    try {
      final list = await DatabaseHelper().getDistinctCurrencies();
      _currencyOptions
        ..clear()
        ..addAll(['all', ...list..sort()]);
      notifyListeners();
    } catch (e) {
      print('Error loading currencies: $e');
    }
  }

  Future<void> _refreshTransactions() async {
    _transactions.clear();
    _currentPage = 0;
    _hasMore = true;
    await _fetchNextPage(reset: true);
    await _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      final allDetails = await AccountDBHelper().getTransactionsForPrint(_account['id']);
      final newBalances = aggregateTransactions(allDetails);
      _balances = newBalances;
      notifyListeners();
    } catch (e) {
      print('Error loading balances: $e');
    }
  }

  Future<void> _fetchNextPage({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    
    _isLoading = reset;
    _isLoadingMore = !reset;
    notifyListeners();

    try {
      final txs = await AccountDBHelper().getTransactions(
        _account['id'],
        offset: _currentPage * _pageSize,
        limit: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        transactionType: _selectedType,
        currency: _selectedCurrency,
        exactDate: _selectedDate,
      );

      if (reset) {
        _transactions.clear();
        _transactions.addAll(txs);
      } else {
        _transactions.addAll(txs);
      }

      _isLoadingMore = false;
      _isLoading = false;
      
      if (txs.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
      
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _isLoading = false;
      notifyListeners();
      print('Error fetching transactions: $e');
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _refreshTransactions();
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void applyFilters({
    String? type,
    String? currency,
    DateTime? date,
  }) {
    _selectedType = type == 'all' ? null : type;
    _selectedCurrency = currency == 'all' ? null : currency;
    _selectedDate = date;
    _refreshTransactions();
  }

  void resetFilters() {
    _selectedType = null;
    _selectedCurrency = null;
    _selectedDate = null;
    _refreshTransactions();
  }

  Future<void> loadMore() async {
    if (_hasMore && !_isLoadingMore && !_isLoading) {
      await _fetchNextPage();
    }
  }

  Future<void> refresh() async {
    await _refreshTransactions();
  }

  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    try {
      if (transaction['transaction_group'] == 'journal') {
        await JournalDBHelper().deleteJournal(transaction['transaction_id']);
        await _refreshTransactions();
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> addJournal(Map<String, dynamic> journalData) async {
    try {
      await JournalDBHelper().insertJournal(
        date: journalData['date'],
        accountId: journalData['account_id'],
        trackId: journalData['track_id'],
        amount: journalData['amount'],
        currency: journalData['currency'],
        transactionType: journalData['transaction_type'],
        description: journalData['description'],
      );
      await _refreshTransactions();
    } catch (e) {
      print('Error adding journal: $e');
      rethrow;
    }
  }

  Future<void> editJournal(Map<String, dynamic> journal, Map<String, dynamic> journalData) async {
    try {
      await JournalDBHelper().updateJournal(
        id: journal['id'],
        date: journalData['date'],
        accountId: journalData['account_id'],
        trackId: journalData['track_id'],
        amount: journalData['amount'],
        currency: journalData['currency'],
        transactionType: journalData['transaction_type'],
        description: journalData['description'],
      );
      await _refreshTransactions();
    } catch (e) {
      print('Error editing journal: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
} 