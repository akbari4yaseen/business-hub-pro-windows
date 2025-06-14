import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../database/journal_db.dart';
import '../../utils/search_manager.dart';
import '../../utils/transaction_share_helper.dart';
import '../../widgets/auth_widget.dart';
import '../../widgets/journal/journal_details_widget.dart';
import '../../widgets/journal/journal_filter_dialog.dart';
import '../../widgets/journal/journal_list.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/journal/journal_form_dialog.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _pageSize = 30;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _amountFormatter = NumberFormat('#,###.##');
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
      _hasMore = newBatch.length == _pageSize;
    });
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _fetchNextPage();
    }

    final atTop = position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  Future<void> _deleteJournal(int id) async {
    await JournalDBHelper().deleteJournal(id);
    await _refreshJournals();
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
            builder: (ctx) => Center(
              // Center so that constrained box is centered on screen
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: 420), // your max width here
                child: AlertDialog(
                  title: Text(loc.confirmDelete),
                  content: Text(loc.confirmDeleteJournal),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _deleteJournal(id);
                      },
                      child: Text(
                        loc.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(Map<String, dynamic> journal) {
    showDialog(
      context: context,
      builder: (_) => JournalDetailsWidget(journal: journal),
    );
  }

void _showFilterModal() {
  String? tmpType = _selectedType;
  String? tmpCurrency = _selectedCurrency;
  DateTime? tmpDate = _selectedDate;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return JournalFilterDialog(
            selectedType: tmpType,
            selectedCurrency: tmpCurrency,
            selectedDate: tmpDate,
            typeOptions: const ['all', 'credit', 'debit'],
            currencyOptions: _currencyOptions,
            onChanged: ({String? type, String? currency, DateTime? date}) {
              setModalState(() {
                if (type != null) tmpType = type;
                if (currency != null) tmpCurrency = currency;
                if (date != null) tmpDate = date;
              });
            },
            onReset: () {
              setModalState(() {
                tmpType = null;
                tmpCurrency = null;
                tmpDate = null;
              });
            },
            onApply: ({type, currency, date}) {
              setState(() {
                _selectedType = tmpType;
                _selectedCurrency = tmpCurrency;
                _selectedDate = tmpDate;
              });
              Navigator.of(context).pop();
              _refreshJournals();
            },
          );
        },
      );
    },
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

  Future<void> _addJournal() async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => JournalFormDialog(
        onSave: (journalData) async {
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
            Navigator.of(dialogContext).pop(journalData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.errorSavingJournal)),
              );
            }
          }
        },
      ),
    );

    if (result != null && mounted) {
      await _refreshJournals();
    }
  }

  Future<void> _editJournal(Map<String, dynamic> journal) async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => JournalFormDialog(
        journal: journal,
        onSave: (journalData) async {
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
            Navigator.of(dialogContext).pop(journalData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.errorSavingJournal)),
              );
            }
          }
        },
      ),
    );

    if (result != null && mounted) {
      await _refreshJournals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                  _refreshJournals();
                },
                hintText: loc.searchJournal,
              )
            : Text(loc.journal, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshJournals,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterModal,
            ),
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
                onEdit: _editJournal,
                onDelete: _confirmDelete,
                amountFormatter: _amountFormatter,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_add_fab',
        onPressed: _isAtTop ? _addJournal : _scrollToTop,
        tooltip: _isAtTop ? loc.addJournal : loc.scrollToTop,
        mini: !_isAtTop,
        child: FaIcon(
          _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
          size: 18,
        ),
      ),
    );
  }

  void _scrollToTop() => _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
}
