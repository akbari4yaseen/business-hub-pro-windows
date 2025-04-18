import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../database/journal_db.dart';
import '../../utils/utilities.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';
import 'journal_search_filter_bar.dart';
import 'journal_filter_bottom_sheet.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const JournalScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _journals = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;
  bool _isAtTop = true;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadJournals();
    _scrollController.addListener(_onScroll);
  }

  @override
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  Future<void> _loadJournals() async {
    setState(() => _isLoading = true);
    try {
      final journals = await JournalDBHelper().getJournals();

      if (mounted) {
        setState(() {
          _journals
            ..clear()
            ..addAll(journals);
        });
      }
    } catch (e) {
      debugPrint('Error loading journals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteJournal(int id) async {
    try {
      await JournalDBHelper().deleteJournal(id);
      await _loadJournals();
    } catch (e) {
      debugPrint('Error deleting journal: $e');
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.confirmDelete),
          content: Text(loc.confirmDeleteJournal),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteJournal(id);
              },
              child:
                  Text(loc.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDetails(Map<String, dynamic> journal) {
    showDialog(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.journalDetails),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${loc.description}: ${journal['description'] ?? loc.noDescription}'),
              Text('${loc.date}: ${journal['date']}'),
              Text(
                  '${loc.amount}: ${NumberFormat('#,###').format(journal['amount'])} ${journal['currency']}'),
              Text('${loc.transactionType}: ${journal['transaction_type']}'),
              Text(
                  '${loc.account}: ${getLocalizedSystemAccountName(context, journal['account_name'])}'),
              Text(
                  '${loc.track}: ${getLocalizedSystemAccountName(context, journal['track_name'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.close),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    return list.where((journal) {
      // Search: only account_name, track_name, description
      if (_searchQuery.isNotEmpty) {
        final desc = (journal['description'] ?? '').toString().toLowerCase();
        final acc = (journal['account_name'] ?? '').toString().toLowerCase();
        final track = (journal['track_name'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        if (!desc.contains(q) && !acc.contains(q) && !track.contains(q)) {
          return false;
        }
      }
      // Transaction type filter
      if (_selectedType != null && _selectedType != 'all' &&
          journal['transaction_type'] != _selectedType) {
        return false;
      }
      // Currency filter
      if (_selectedCurrency != null && _selectedCurrency != 'all' &&
          journal['currency'] != _selectedCurrency) {
        return false;
      }
      // Date filter
      if (_selectedDate != null) {
        final jDate = DateTime.tryParse(journal['date'].toString());
        if (jDate == null ||
            jDate.year != _selectedDate!.year ||
            jDate.month != _selectedDate!.month ||
            jDate.day != _selectedDate!.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showFilterModal() {
    String? tmpType = _selectedType;
    String? tmpCurrency = _selectedCurrency;
    DateTime? tmpDate = _selectedDate;

    // Transaction types: credit, debit
    final typeList = ['all', 'credit', 'debit'];
    // Extract unique currencies from _journals
    final currencies = <String>{};
    for (final j in _journals) {
      if (j['currency'] != null) currencies.add(j['currency'].toString());
    }
    final currencyList = ['all', ...currencies.toList()..sort()];

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
            currencyOptions: currencyList,
            onChanged: ({type, currency, date}) {
              setModal(() {
                if (type != null) tmpType = type;
                if (currency != null) tmpCurrency = currency;
                if (date != null) tmpDate = date;
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations loc) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: loc.search,
          border: InputBorder.none,
          prefixIcon: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _isSearching = false;
              });
            },
            splashRadius: 20,
            tooltip: loc.cancel,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  splashRadius: 20,
                  tooltip: loc.clear,
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final filteredJournals = _applyFilters(_journals);

    Widget bodyContent;
    if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (filteredJournals.isEmpty) {
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
        itemCount: filteredJournals.length,
        itemBuilder: (ctx, i) {
          final j = filteredJournals[i];
          final icon = j['transaction_type'] == 'credit'
              ? FontAwesomeIcons.plus
              : FontAwesomeIcons.minus;
          final color =
              j['transaction_type'] == 'credit' ? Colors.green : Colors.red;

          return Card(
            elevation: 0,
            shape:
                const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 18),
              ),
              title: Text(
                  '${getLocalizedSystemAccountName(context, j['account_name'])} — ${getLocalizedSystemAccountName(context, j['track_name'])}',
                  style: const TextStyle(fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${NumberFormat('#,###.##').format(j['amount'])} ${j['currency']}',
                      style: const TextStyle(fontSize: 14)),
                  Text(formatJalaliDate(j['date']),
                      style: const TextStyle(fontSize: 13)),
                  Text(j['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'details':
                      _showDetails(j);
                      break;
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditJournalScreen(journal: j)),
                      ).then((_) => _loadJournals());
                      break;
                    case 'delete':
                      _confirmDelete(j['id']);
                      break;
                    case 'share':
                    case 'print':
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
            ? _buildSearchField(loc)
            : Text(loc.journal, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
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
        onRefresh: _loadJournals,
        child: bodyContent,
      ),
      floatingActionButton: FloatingActionButton(
        mini: !_isAtTop,
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
            size: 18),
        onPressed: _isAtTop
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddJournalScreen()),
                ).then((_) => _loadJournals())
            : () => _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut),
      ),
    );
  }
}

