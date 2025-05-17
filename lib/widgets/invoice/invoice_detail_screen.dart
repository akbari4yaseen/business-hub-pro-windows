import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/info_provider.dart';
import '../../providers/account_provider.dart';
import 'record_payment_dialog.dart';
import 'print_invoice.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  static final _dateFormat = DateFormat('MMM d, y');
  static final _currencyFormat = NumberFormat('#,##0.00');

  const InvoiceDetailScreen({
    Key? key,
    required this.invoice,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          if (invoice.status != InvoiceStatus.draft &&
              invoice.status != InvoiceStatus.paid &&
              invoice.status != InvoiceStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => RecordPaymentDialog(
                    invoice: invoice,
                    onPaymentRecorded: (invoice, amount) {
                      context.read<InvoiceProvider>().recordPayment(
                            invoice.id!,
                            amount,
                          );
                    },
                  ),
                );
              },
              tooltip: 'Record Payment',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'Print Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Customer: ' + customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
                  ),
                );
              },
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                invoice.status.toString().split('.').last.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Date',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _dateFormat.format(invoice.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (invoice.dueDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Due Date',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _dateFormat.format(invoice.dueDate!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: invoice.isOverdue ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Items
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoice.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = invoice.items[index];
                  return Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      final product = provider.currentStock.firstWhere(
                        (p) => p['id'] == item.productId,
                        orElse: () => {'product_name': 'Unknown Product'},
                      );

                      return ListTile(
                        title: Text(product['product_name'] as String),
                        subtitle: item.description != null
                            ? Text(item.description!)
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          '${_currencyFormat.format(invoice.subtotal)} ${invoice.currency}',
                        ),
                      ],
                    ),
                    if (invoice.paidAmount != null &&
                        invoice.paidAmount! > 0) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid Amount'),
                          Text(
                            '${_currencyFormat.format(invoice.paidAmount)} ${invoice.currency}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance Due',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_currencyFormat.format(invoice.balance)} ${invoice.currency}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: invoice.balance > 0
                                ? invoice.isOverdue
                                    ? Colors.red
                                    : Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(invoice.notes!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    await printInvoice(
      context: context,
      invoice: invoice,
      infoProvider: context.read<InfoProvider>(),
      inventoryProvider: context.read<InventoryProvider>(),
      accountProvider: context.read<AccountProvider>(),
    );
  }
}
