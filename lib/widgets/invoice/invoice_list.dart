import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import 'record_payment_dialog.dart';
import 'invoice_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';

class InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final bool showOverdueWarning;
  final Function(Invoice, double) onPaymentRecorded;
  final Function(Invoice) onInvoiceFinalized;

  const InvoiceList({
    Key? key,
    required this.invoices,
    this.showOverdueWarning = false,
    required this.onPaymentRecorded,
    required this.onInvoiceFinalized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Text(
          showOverdueWarning 
            ? 'No overdue invoices'
            : 'No invoices found',
        ),
      );
    }

    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        try {
          final invoice = invoices[index];
          return InvoiceListItem(
            invoice: invoice,
            showOverdueWarning: showOverdueWarning,
            onPaymentRecorded: onPaymentRecorded,
            onInvoiceFinalized: onInvoiceFinalized,
          );
        } catch (e) {
          debugPrint('Error rendering invoice item at index $index: $e');
          return const SizedBox.shrink();
        }
      },
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }
}

class InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  final bool showOverdueWarning;
  final Function(Invoice, double) onPaymentRecorded;
  final Function(Invoice) onInvoiceFinalized;

  static final _dateFormat = DateFormat('MMM d, y');
  static final _currencyFormat = NumberFormat('#,##0.00');

  const InvoiceListItem({
    Key? key,
    required this.invoice,
    required this.showOverdueWarning,
    required this.onPaymentRecorded,
    required this.onInvoiceFinalized,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.finalized:
        return Colors.blue;
      case InvoiceStatus.partiallyPaid:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  void _showRecordPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        invoice: invoice,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => _showInvoiceDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AccountProvider>(
                  builder: (context, accountProvider, child) {
                    final customer = accountProvider.customers.firstWhere(
                      (c) => c['id'] == invoice.accountId,
                      orElse: () => <String, dynamic>{'name': 'Unknown Customer'},
                    );
                    final customerName = customer['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'Customer: ' + customerName,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        invoice.status.toString().split('.').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${_dateFormat.format(invoice.date)}'),
                    if (invoice.dueDate != null)
                      Text(
                        'Due: ${_dateFormat.format(invoice.dueDate!)}',
                        style: TextStyle(
                          color: invoice.isOverdue ? Colors.red : null,
                          fontWeight: invoice.isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ${_currencyFormat.format(invoice.total)} ${invoice.currency}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (invoice.paidAmount != null && invoice.paidAmount! > 0)
                      Text(
                        'Paid: ${_currencyFormat.format(invoice.paidAmount)} ${invoice.currency}',
                        style: const TextStyle(color: Colors.green),
                      ),
                  ],
                ),
                if (invoice.balance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Balance: ${_currencyFormat.format(invoice.balance)} ${invoice.currency}',
                      style: TextStyle(
                        color: invoice.isOverdue ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (showOverdueWarning && invoice.isOverdue)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Overdue by ${DateTime.now().difference(invoice.dueDate!).inDays} days',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (invoice.status == InvoiceStatus.draft)
                      TextButton(
                        onPressed: () => onInvoiceFinalized(invoice),
                        child: const Text('Finalize'),
                      ),
                    if (invoice.status != InvoiceStatus.draft &&
                        invoice.status != InvoiceStatus.paid &&
                        invoice.status != InvoiceStatus.cancelled)
                      TextButton(
                        onPressed: () => _showRecordPaymentDialog(context),
                        child: const Text('Record Payment'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 