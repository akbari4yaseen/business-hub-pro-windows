import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../database/journal_db.dart';
import '../../utils/utilities.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const JournalScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _journals = [];
  bool _isAtTop = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
              Text('${loc.account}: ${journal['account_name']}'),
              Text('${loc.track}: ${journal['track_name']}'),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    Widget bodyContent;
    if (_isLoading) {
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
        itemCount: _journals.length,
        itemBuilder: (ctx, i) {
          final j = _journals[i];
          final isCredit = j['transaction_type'] == 'credit';
          return Card(
            elevation: 0,
            shape:
                const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: CircleAvatar(
                backgroundColor: isCredit ? Colors.green[400] : Colors.red[400],
                child: FaIcon(
                  isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text('${j['account_name']} — ${j['track_name']}',
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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        title: Text(loc.journal),
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
