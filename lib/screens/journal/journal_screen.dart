import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';

import '../../database/journal_db.dart';
import '../../database/database_helper.dart';
import '../../widgets/journal/journal_filter_bottom_sheet.dart';
import '../../widgets/journal/journal_list.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/auth_widget.dart';
import '../../widgets/journal/journal_details_widget.dart';
import '../../utils/search_manager.dart';
import '../../utils/transaction_share_helper.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const JournalScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _pageSize = 30;
  final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final SearchManager _searchManager;

  final List<Map<String, dynamic>> _journals = [];
  final List<String> _currencyOptions = ['all'];

  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSearching = false;
  bool _isAtTop = true;

  int _currentPage = 0;

  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchManager = SearchManager();
    _scrollController.addListener(_onScroll);
    _searchManager.searchStream.listen((searchState) {
      setState(() {
        _searchController.text = searchState.query;
        _journals
          ..clear()
          ..addAll(searchState.results);
        _hasMore = false;
      });
    });

    _loadCurrencies();
    _refreshJournals();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchManager.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final list = await DatabaseHelper().getDistinctCurrencies();
    setState(() {
      _currencyOptions
        ..clear()
        ..addAll(['all', ...list..sort()]);
    });
  }

  Future<void> _refreshJournals() async {
    _currentPage = 0;
    _journals.clear();
    _hasMore = true;
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);

    final newBatch = await JournalDBHelper().getJournalsPage(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      searchQuery: _searchController.text,
      transactionType: _selectedType,
      currency: _selectedCurrency,
      exactDate: _selectedDate,
    );

    setState(() {
      _journals.addAll(newBatch);
      _isLoading = false;
      _currentPage++;
      if (newBatch.length < _pageSize) _hasMore = false;
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _fetchNextPage();
    final atTop = pos.pixels <= 0;
    if (atTop != _isAtTop) setState(() => _isAtTop = atTop);
  }

  Future<void> _deleteJournal(int id) async {
    try {
      await JournalDBHelper().deleteJournal(id);
      await _refreshJournals();
    } catch (e) {
      // debugPrint('Error deleting journal: $e');
    }
  }

  void _confirmDelete(int id) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AuthWidget(
        actionReason: loc.deleteJournalAuthMessage,
        onAuthenticated: () {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(loc.confirmDelete),
              content: Text(loc.confirmDeleteJournal),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(loc.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteJournal(id);
                  },
                  child: Text(loc.delete,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetails(Map<String, dynamic> journal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JournalDetailsWidget(journal: journal),
    );
  }

  void _showFilterModal() {
    String? tmpType = _selectedType;
    String? tmpCurrency = _selectedCurrency;
    DateTime? tmpDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Material(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: JournalFilterBottomSheet(
            selectedType: tmpType,
            selectedCurrency: tmpCurrency,
            selectedDate: tmpDate,
            typeOptions: const ['all', 'credit', 'debit'],
            currencyOptions: _currencyOptions,
            onChanged: ({String? type, String? currency, DateTime? date}) =>
                setModal(() {
              if (type != null) tmpType = type;
              if (currency != null) tmpCurrency = currency;
              if (date != null) tmpDate = date;
            }),
            onReset: () => setModal(() {
              tmpType = null;
              tmpCurrency = null;
              tmpDate = null;
            }),
            onApply: ({type, currency, date}) {
              setState(() {
                _selectedType = tmpType;
                _selectedCurrency = tmpCurrency;
                _selectedDate = tmpDate;
              });
              Navigator.of(context).pop();
              _refreshJournals();
            },
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _refreshJournals();
    } else {
      final results = await JournalDBHelper().searchJournals(
        query: query,
        transactionType: _selectedType,
        currency: _selectedCurrency,
        exactDate: _selectedDate,
      );
      _searchManager.updateSearch(query, results);
    }
  }

  void _shareJournal(Map<String, dynamic> journal) {
    shareJournalEntry(context, journal);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: widget.openDrawer),
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
                  _refreshJournals();
                },
                hintText: loc.searchJournal,
              )
            : Text(loc.journal, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!_isSearching) ...[
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearching = true)),
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterModal),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshJournals,
              child: JournalList(
                journals: _journals,
                isLoading: _isLoading,
                hasMore: _hasMore,
                onShare: _shareJournal,
                scrollController: _scrollController,
                onDetails: _showDetails,
                onEdit: (j) => Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => EditJournalScreen(journal: j)))
                    .then((_) => _refreshJournals()),
                onDelete: (id) => _confirmDelete(id),
                amountFormatter: _amountFormatter,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_add_fab',
        mini: !_isAtTop,
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
            size: 18),
        onPressed: () {
          if (_isAtTop) {
            Navigator.of(context)
                .push(
                    MaterialPageRoute(builder: (_) => const AddJournalScreen()))
                .then((_) => _refreshJournals());
          } else {
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut);
          }
        },
      ),
    );
  }
}
