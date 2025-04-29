import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../utils/date_formatters.dart';

import '../../database/journal_db.dart';
import '../../database/database_helper.dart';
import '../../utils/utilities.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';
import '../../widgets/journal_filter_bottom_sheet.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/journal_details_widget.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const JournalScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _pageSize = 30;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSearching = false;
  int _currentPage = 0;
  bool _isAtTop = true;

  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;
  List<String> currencyOptions = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshJournals();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Infinite‐scroll trigger
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchNextPage();
    }

    // FAB up/down
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) setState(() => _isAtTop = atTop);
  }

  Future<void> _refreshJournals() async {
    setState(() {
      _journals.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (!_hasMore) return;

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

  Future<void> _deleteJournal(int id) async {
    try {
      await JournalDBHelper().deleteJournal(id);
      await _refreshJournals();
    } catch (e) {
      debugPrint('Error deleting journal: $e');
    }
  }

  Future<void> _loadCurrencies() async {
    final list = await DatabaseHelper().getDistinctCurrencies();
    list.sort();
    currencyOptions = ['all', ...list];
  }

  void _confirmDelete(int id) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.confirmDeleteJournal),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteJournal(id);
            },
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> j) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalDetailsWidget(journal: j),
    );
  }

  void _showFilterModal() {
    String? tmpType = _selectedType;
    String? tmpCurrency = _selectedCurrency;
    DateTime? tmpDate = _selectedDate;
    _loadCurrencies();

    final typeList = ['all', 'credit', 'debit'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c2, setModal) => Material(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: JournalFilterBottomSheet(
            selectedType: tmpType,
            selectedCurrency: tmpCurrency,
            selectedDate: tmpDate,
            typeOptions: typeList,
            currencyOptions: currencyOptions,
            onChanged: ({type, currency, date}) {
              setModal(() {
                tmpType = type;
                tmpCurrency = currency;
                tmpDate = date;
              });
            },
            onReset: () {
              setModal(() {
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
              Navigator.pop(context);
              _refreshJournals();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    Widget bodyContent;
    if (_journals.isEmpty && _isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_journals.isEmpty) {
      bodyContent = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 100),
        children: [Center(child: Text(loc.noJournalEntries))],
      );
    } else {
      bodyContent = ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: _journals.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _journals.length) {
            // bottom loader
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final j = _journals[i];
          final icon = j['transaction_type'] == 'credit'
              ? FontAwesomeIcons.plus
              : FontAwesomeIcons.minus;
          final color =
              j['transaction_type'] == 'credit' ? Colors.green : Colors.red;

          return Card(
            elevation: 0,
            shape:
                const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 18),
              ),
              title: Text(
                '${getLocalizedSystemAccountName(context, j['account_name'])} — '
                '${getLocalizedSystemAccountName(context, j['track_name'])}',
                style: const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u200E${_amountFormatter.format(j['amount'])} ${j['currency']}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text('${formatLocalizedDateTime(context, j['date'])}',
                      style: const TextStyle(fontSize: 13)),
                  Text(
                    j['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'details':
                      _showDetails(j);
                      break;
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditJournalScreen(journal: j),
                        ),
                      ).then((_) => _refreshJournals());
                      break;
                    case 'delete':
                      _confirmDelete(j['id']);
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'details',
                      child: ListTile(
                          leading: const Icon(Icons.info),
                          title: Text(loc.details))),
                  PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                          leading: const Icon(Icons.share),
                          title: Text(loc.share))),
                  PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: Text(loc.edit))),
                  PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          title: Text(loc.delete))),
                  PopupMenuItem(
                      value: 'print',
                      enabled: false,
                      child: ListTile(
                          leading: const Icon(Icons.print, color: Colors.grey),
                          title: Text(loc.printDisabled))),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 500),
                isLoading: _isLoading,
                onChanged: (_) => _refreshJournals(),
                onSubmitted: (_) => _refreshJournals(),
                onCancel: () => setState(() => _isSearching = false),
                onClear: () {
                  _searchController.clear();
                  _refreshJournals();
                },
                hintText: loc.searchJournal,
              )
            : Text(loc.journal, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: loc.search,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
            tooltip: loc.filter,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshJournals,
        child: bodyContent,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_add_fab',
        mini: !_isAtTop,
        child: FaIcon(
          _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
          size: 18,
        ),
        onPressed: () {
          if (_isAtTop) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddJournalScreen()),
            ).then((_) => _refreshJournals());
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
