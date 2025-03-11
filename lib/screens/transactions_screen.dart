import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  final Map<String, dynamic> account;

  const TransactionsScreen({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(account['name'], style: TextStyle(fontSize: 18)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: account['transactions']?.length ?? 0,
        itemBuilder: (context, index) {
          final transaction = account['transactions'][index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              title: Text(transaction['description'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text(
                "${transaction['date']}\nAmount: ${NumberFormat('#,###.##').format(transaction['amount'])} ${transaction['currency']}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: Icon(
                transaction['amount'] > 0
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: transaction['amount'] > 0 ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
