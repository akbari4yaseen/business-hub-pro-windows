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
    // Update _isAtTop only if the value changes to avoid unnecessary rebuilds
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
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading journals: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteJournal(int id) async {
    await JournalDBHelper().deleteJournal(id);
    _loadJournals();
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
              ? const Center(child: Text("No journal entries found."))
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
                            child: Icon(
                              journal['transaction_type'] == 'credit'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            journal['description'] ?? "No Description",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${journal['date']} - ${NumberFormat('#,###').format(journal['amount'])} ${journal['currency']} (${journal['transaction_type']})",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "From: ${journal['account_name']} → To: ${journal['track_name']}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditJournalScreen(journal: journal),
                                    ),
                                  ).then((_) => _loadJournals());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteJournal(journal['id']),
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
