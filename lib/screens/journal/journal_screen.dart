import '../../utils/utilities.dart';
import 'package:flutter/material.dart';
import '../../database/journal_db.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Map<String, dynamic>> _journals = [];
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
    _scrollController.addListener(_updateScrollPosition);
  }

  void _updateScrollPosition() {
    if (!mounted) return;
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() {
        _isAtTop = atTop;
      });
    }
  }

  Future<void> _loadJournals() async {
    try {
      final journals = await JournalDBHelper().getJournals();
      if (mounted) {
        setState(() {
          _journals = journals;
        });
      }
    } catch (e) {
      print("Error loading journals: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteJournal(int id) async {
    try {
      await JournalDBHelper().deleteJournal(id);
      _loadJournals();
    } catch (e) {
      print("Error deleting journal: $e");
    }
  }

  Future<void> _confirmDeleteJournal(int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDelete),
          content: Text(AppLocalizations.of(context)!.confirmDeleteJournal),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deleteJournal(id); // Proceed with deletion
              },
              child: Text(AppLocalizations.of(context)!.delete,
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showJournalDetails(Map<String, dynamic> journal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.journalDetails),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "${AppLocalizations.of(context)!.description}: ${journal['description'] ?? AppLocalizations.of(context)!.noDescription}"),
                Text(
                    "${AppLocalizations.of(context)!.date}: ${journal['date']}"),
                Text(
                    "${AppLocalizations.of(context)!.amount}: ${NumberFormat('#,###').format(journal['amount'])} ${journal['currency']}"),
                Text(
                    "${AppLocalizations.of(context)!.transactionType}: ${journal['transaction_type']}"),
                Text(
                    "${AppLocalizations.of(context)!.account}: ${journal['account_name']}"),
                Text(
                    "${AppLocalizations.of(context)!.track}: ${journal['track_name']}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadJournals,
              child: _journals.isEmpty
                  ? ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 70),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text("No journal entries found.")),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 70),
                      itemCount: _journals.length,
                      itemBuilder: (context, index) {
                      final journal = _journals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.zero),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                journal['transaction_type'] == 'credit'
                                    ? Colors.green[400]
                                    : Colors.red[400],
                            child: FaIcon(
                              journal['transaction_type'] == 'credit'
                                  ? FontAwesomeIcons.plus
                                  : FontAwesomeIcons.minus,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            "${journal['account_name']} — ${journal['track_name']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${NumberFormat('#,###.##').format(journal['amount'])} ${journal['currency']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                formatJalaliDate(journal['date']),
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                journal['description'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'details':
                                  _showJournalDetails(journal);
                                  break;
                                case 'share':
                                  // TODO: Implement share functionality
                                  break;
                                case 'edit':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditJournalScreen(journal: journal),
                                    ),
                                  ).then((_) => _loadJournals());
                                  break;
                                case 'delete':
                                  await _confirmDeleteJournal(journal['id']);
                                  break;

                                case 'print':
                                  // Print is disabled, do nothing
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'details',
                                child: ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text(
                                      AppLocalizations.of(context)!.details),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'share',
                                child: ListTile(
                                  leading: Icon(Icons.share),
                                  title:
                                      Text(AppLocalizations.of(context)!.share),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit, color: Colors.blue),
                                  title:
                                      Text(AppLocalizations.of(context)!.edit),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  title: Text(
                                      AppLocalizations.of(context)!.delete),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'print',
                                enabled: false,
                                child: ListTile(
                                  leading:
                                      Icon(Icons.print, color: Colors.grey),
                                  title: Text(AppLocalizations.of(context)!
                                      .printDisabled),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: FaIcon(
          _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
          size: 18,
        ),
        mini: !_isAtTop,
        onPressed: _isAtTop
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddJournalScreen(),
                  ),
                ).then((_) => _loadJournals());
              }
            : _scrollToTop,
      ),
    );
  }
}
