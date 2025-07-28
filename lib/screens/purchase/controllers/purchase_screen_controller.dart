import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/purchase.dart';
import '../../../database/purchase_db.dart';

class PurchaseScreenController extends ChangeNotifier {
  // Search and filter state
  String _searchQuery = '';
  String? _selectedSupplier;
  String? _selectedCurrency;
  DateTime? _selectedDate;
  bool _hasActiveFilters = false;
  bool _isSearching = false;
  bool _isLoading = false;

  // Data
  final List<Map<String, dynamic>> _purchases = [];
  final List<String> _currencyOptions = ['all'];
  final List<String> _supplierOptions = ['all'];

  // Getters
  String get searchQuery => _searchQuery;
  String? get selectedSupplier => _selectedSupplier;
  String? get selectedCurrency => _selectedCurrency;
  DateTime? get selectedDate => _selectedDate;
  bool get hasActiveFilters => _hasActiveFilters;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get purchases => _purchases;
  List<String> get currencyOptions => _currencyOptions;
  List<String> get supplierOptions => _supplierOptions;

  // Initialize
  Future<void> initialize() async {
    await Future.wait([
      _loadCurrencies(),
      _loadSuppliers(),
      _loadPurchases(),
    ]);
  }

  // Load currencies
  Future<void> _loadCurrencies() async {
    try {
      final currencies = await PurchaseDBHelper().getDistinctCurrencies();
      _currencyOptions
        ..clear()
        ..addAll(['all', ...currencies..sort()]);
      notifyListeners();
    } catch (e) {
      print('Error loading currencies: $e');
    }
  }

  // Load suppliers
  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await PurchaseDBHelper().getDistinctSuppliers();
      _supplierOptions
        ..clear()
        ..addAll(['all', ...suppliers]);
      notifyListeners();
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  // Load purchases
  Future<void> _loadPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final purchases = await PurchaseDBHelper().getPurchases(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        supplierId: _getSelectedSupplierId(),
        currency: _selectedCurrency,
        startDate: _selectedDate,
        endDate: _selectedDate,
      );
      
      _purchases.clear();
      _purchases.addAll(purchases);
    } catch (e) {
      print('Error loading purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get selected supplier ID
  int? _getSelectedSupplierId() {
    if (_selectedSupplier == null || _selectedSupplier == 'all') return null;
    final supplierIdMatch = RegExp(r'\((\d+)\)').firstMatch(_selectedSupplier!);
    if (supplierIdMatch != null) {
      return int.tryParse(supplierIdMatch.group(1)!);
    }
    return null;
  }

  // Search methods
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _loadPurchases();
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  // Filter methods
  void applyFilters({
    String? supplier,
    String? currency,
    DateTime? date,
  }) {
    _selectedSupplier = supplier == 'all' ? null : supplier;
    _selectedCurrency = currency == 'all' ? null : currency;
    _selectedDate = date;
    _hasActiveFilters = _selectedSupplier != null || _selectedCurrency != null || _selectedDate != null;
    
    _refreshPurchases();
  }

  void resetFilters() {
    _selectedSupplier = null;
    _selectedCurrency = null;
    _selectedDate = null;
    _hasActiveFilters = false;
    
    _refreshPurchases();
  }

  // Refresh purchases
  Future<void> _refreshPurchases() async {
    _purchases.clear();
    notifyListeners();
    await _loadPurchases();
  }

  // Refresh all data
  Future<void> refresh() async {
    await _refreshPurchases();
  }

  // Delete purchase
  Future<void> deletePurchase(Map<String, dynamic> purchase) async {
    try {
      await PurchaseDBHelper().deletePurchase(purchase['id'] as int);
      await _refreshPurchases();
    } catch (e) {
      print('Error deleting purchase: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
} 