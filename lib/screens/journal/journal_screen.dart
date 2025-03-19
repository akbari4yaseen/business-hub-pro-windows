import '../../utils/utilities.dart';
import 'package:flutter/material.dart';
import '../../database/journal_db.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  void _showJournalDetails(Map<String, dynamic> journal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Journal Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "Description: ${journal['description'] ?? 'No Description'}"),
                Text("Date: ${journal['date']}"),
                Text(
                    "Amount: ${NumberFormat('#,###').format(journal['amount'])} ${journal['currency']}"),
                Text("Transaction Type: ${journal['transaction_type']}"),
                Text(
                  "Account: ${journal['account_name']}",
                ),
                Text(
                  "Track: ${journal['track_name']}",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
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
          : _journals.isEmpty
              ? const Center(
                  child: Text("No journal entries found."),
                )
              : RefreshIndicator(
                  onRefresh: _loadJournals,
                  child: ListView.builder(
                    controller: _scrollController,
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
                                  await _deleteJournal(journal['id']);
                                  break;
                                case 'print':
                                  // Print is disabled, do nothing
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'details',
                                child: ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text('Details'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: ListTile(
                                  leading: Icon(Icons.share),
                                  title: Text('Share'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit, color: Colors.blue),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  title: Text('Delete'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'print',
                                enabled: false,
                                child: ListTile(
                                  leading:
                                      Icon(Icons.print, color: Colors.grey),
                                  title: Text('Print (Disabled)'),
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
