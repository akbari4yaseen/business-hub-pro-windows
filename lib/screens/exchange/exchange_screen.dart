import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'exchange_form_screen.dart';
import '../../database/exchange_db.dart';
import '../../models/exchange.dart';
import '../../widgets/exchange_list_widget.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/exchange_filter_modal.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  _ExchangeScreenState createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _exchangeDb = ExchangeDBHelper();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Exchange> _exchanges = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _selectedFromCurrency;
  String? _selectedToCurrency;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreExchanges();
    }
  }

  Future<void> _loadMoreExchanges() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final exchanges = await _exchangeDb.getExchanges(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text,
        fromCurrency: _selectedFromCurrency,
        toCurrency: _selectedToCurrency,
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
      );
      setState(() {
        _exchanges.addAll(exchanges);
        _hasMore = exchanges.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more exchanges: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _exchanges.clear();
      _hasMore = true;
    });
    try {
      final exchanges = await _exchangeDb.getExchanges(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text,
        fromCurrency: _selectedFromCurrency,
        toCurrency: _selectedToCurrency,
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
      );
      setState(() {
        _exchanges.addAll(exchanges);
        _hasMore = exchanges.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.errorRefreshingData}: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _refreshData();
    } else {
      setState(() => _isLoading = true);
      try {
        final results = await _exchangeDb.searchExchanges(
          query: query,
          fromCurrency: _selectedFromCurrency,
          toCurrency: _selectedToCurrency,
          fromDate: _selectedFromDate,
          toDate: _selectedToDate,
        );
        if (mounted) {
          setState(() {
            _exchanges.clear();
            _exchanges.addAll(results);
            _hasMore = false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error searching exchanges: $e')),
          );
        }
      }
    }
  }

  void _showFilterModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExchangeFilterModal(
        initialFromDate: _selectedFromDate,
        initialToDate: _selectedToDate,
        onApplyFilters: (fromDate, toDate) {
          setState(() {
            _selectedFromDate = fromDate;
            _selectedToDate = toDate;
          });
          _refreshData();
        },
      ),
    );
  }

  Future<void> _deleteExchange(Exchange exchange) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteExchangeTitle),
        content: Text(loc.deleteExchangeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _exchangeDb.deleteExchange(exchange.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.exchangeDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${loc.errorDeletingExchange}: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showExchangeForm([Exchange? editingExchange]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExchangeFormScreen(
          exchange: editingExchange,
        ),
      ),
    );

    if (result == true && mounted) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading && _exchanges.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 500),
                isLoading: _isLoading,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                onCancel: () {
                  setState(() => _isSearching = false);
                  _searchController.clear();
                },
                hintText: loc.search,
              )
            : Text(loc.exchange),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterModal,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: ExchangeListWidget(
          exchanges: _exchanges,
          isLoading: _isLoading,
          hasMore: _hasMore,
          scrollController: _scrollController,
          onEdit: _showExchangeForm,
          onDelete: _deleteExchange,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExchangeForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
