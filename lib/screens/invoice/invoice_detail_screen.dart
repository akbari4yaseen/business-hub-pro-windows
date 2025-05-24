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

  const InvoiceDetailScreen({Key? key, required this.invoice})
      : super(key: key);

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
        title: Text('${invoice.invoiceNumber}'),
        actions: _buildAppBarActions(context, loc),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerName(context, loc),
            const SizedBox(height: 8),
            _buildDateAndStatusRow(context, loc),
            const SizedBox(height: 24),
            _buildItemsSection(context, loc),
            const SizedBox(height: 24),
            _buildTotalsSection(loc),
            if (invoice.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 24),
              Text(loc.note, style: _sectionTitleStyle),
              const SizedBox(height: 8),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(invoice.notes!))),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, AppLocalizations loc) {
    return [
      if (invoice.status == InvoiceStatus.draft) ...[
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: loc.editInvoice,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(invoice: invoice)),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: loc.deleteInvoice,
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ],
      if ([InvoiceStatus.finalized, InvoiceStatus.partiallyPaid]
          .contains(invoice.status))
        IconButton(
          icon: const Icon(Icons.payment),
          tooltip: loc.recordPayment,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => RecordPaymentDialog(
                invoice: invoice,
                onPaymentRecorded: (inv, amount) {
                  context
                      .read<InvoiceProvider>()
                      .recordPayment(inv.id!, amount, loc.paymentForInvoice);
                },
              ),
            );
          },
        ),
      IconButton(
        icon: const Icon(Icons.print),
        tooltip: loc.printInvoice,
        onPressed: () => _printInvoice(context),
      ),
    ];
  }

  Widget _buildCustomerName(BuildContext context, AppLocalizations loc) {
    return Consumer<AccountProvider>(
      builder: (_, accountProvider, __) {
        final customer = accountProvider.customers.firstWhere(
            (c) => c['id'] == invoice.accountId,
            orElse: () => {'name': 'Unknown Customer'});
        return Text('${loc.customer}: ${customer['name']}',
            style: _sectionTitleStyle);
      },
    );
  }

  Widget _buildDateAndStatusRow(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.invoiceDate,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              formatLocalizedDate(context, invoice.date.toString()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        _buildStatusBadge(loc),
      ],
    );
  }

  Widget _buildStatusBadge(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        invoice.status.localizedName(loc).toUpperCase(),
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.items, style: _sectionTitleStyle),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoice.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = invoice.items[index];
              return Consumer<InventoryProvider>(
                builder: (_, provider, __) {
                  final product = provider.currentStock.firstWhere(
                    (p) => p['id'] == item.productId,
                    orElse: () => {'product_name': 'Unknown Product'},
                  );
                  return ListTile(
                    title: Text(product['product_name'] as String),
                    subtitle: item.description?.isNotEmpty == true
                        ? Text(item.description!)
                        : null,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _currencyFormat.format(item.total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection(AppLocalizations loc) {
    final balanceColor = invoice.balance <= 0
        ? Colors.green
        : invoice.isOverdue
            ? Colors.red
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalsRow(loc.subtotal, invoice.subtotal),
            if (invoice.paidAmount != null && invoice.paidAmount! > 0) ...[
              const Divider(),
              _totalsRow(loc.paidAmount, invoice.paidAmount!,
                  color: Colors.green),
            ],
            const Divider(),
            _totalsRow(loc.balanceDue, invoice.balance,
                isBold: true, color: balanceColor),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, num amount,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        Text(
          '\u200E${_currencyFormat.format(amount)} ${invoice.currency}',
          style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null, color: color),
        ),
      ],
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
      builder: (_) => AlertDialog(
        title: Text(loc.deleteInvoice),
        content: Text(loc.deleteInvoiceConfirmation),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<InvoiceProvider>().deleteInvoice(invoice.id!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(loc.invoiceDeleted)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${loc.errorDeletingInvoice}: $e'),
          ));
        }
      }
    }
  }

  TextStyle get _sectionTitleStyle =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
}
