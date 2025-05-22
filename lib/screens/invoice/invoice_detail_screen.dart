import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/date_formatters.dart';
import '../../utils/invoice.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/info_provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/invoice/record_payment_dialog.dart';
import '../../widgets/invoice/print_invoice.dart';
import '../../themes/app_theme.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  static final _currencyFormat = NumberFormat('#,###.##');

  const InvoiceDetailScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.finalized:
        return AppTheme.primaryColor;
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.invoice} ${invoice.invoiceNumber}'),
        actions: [
          if (invoice.status == InvoiceStatus.draft) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateInvoiceScreen(
                      invoice: invoice,
                    ),
                  ),
                );
              },
              tooltip: loc.editInvoice,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: loc.deleteInvoice,
            ),
          ],
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
              tooltip: loc.recordPayment,
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: loc.printInvoice,
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
                    '${loc.customer}: $customerName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                invoice.status.localizedName(loc).toString().toUpperCase(),
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
                    Text(
                      loc.invoiceDate,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatLocalizedDate(context, invoice.date.toString()),
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
                      Text(
                        loc.dueDate,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatLocalizedDate(
                            context, invoice.dueDate.toString()),
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
            Text(
              loc.items,
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
                        Text(loc.subtotal),
                        Text(
                          '\u200E${_currencyFormat.format(invoice.subtotal)} ${invoice.currency}',
                        ),
                      ],
                    ),
                    if (invoice.paidAmount != null &&
                        invoice.paidAmount! > 0) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.paidAmount),
                          Text(
                            '\u200E${_currencyFormat.format(invoice.paidAmount)} ${invoice.currency}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.balanceDue,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\u200E${_currencyFormat.format(invoice.balance)} ${invoice.currency}',
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
              Text(
                loc.note,
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

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteInvoice),
        content: Text(loc.deleteInvoiceConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<InvoiceProvider>().deleteInvoice(invoice.id!);
        if (context.mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.invoiceDeleted)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.errorDeletingInvoice}: $e')),
          );
        }
      }
    }
  }
}
