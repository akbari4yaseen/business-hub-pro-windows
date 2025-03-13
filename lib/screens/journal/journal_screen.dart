import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'add_journal_screen.dart';
import 'edit_journal_screen.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      List<Map<String, dynamic>> journals =
          await DatabaseHelper().getJournals();
      setState(() {
        _journals = journals;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading journals: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteJournal(int id) async {
    await DatabaseHelper().deleteJournal(id);
    _loadJournals();
  }

  @override
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
                    itemCount: _journals.length,
                    itemBuilder: (context, index) {
                      final journal = _journals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.zero)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                journal['transaction_type'] == 'credit'
                                    ? Colors.green
                                    : Colors.red,
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
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
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
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddJournalScreen()),
          ).then((_) => _loadJournals());
        },
      ),
    );
  }
}
