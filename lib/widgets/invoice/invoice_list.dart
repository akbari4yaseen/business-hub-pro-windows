import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'record_payment_dialog.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../utils/date_formatters.dart';
import '../../utils/invoice.dart';
import '../../screens/invoice/invoice_detail_screen.dart';
import '../../providers/account_provider.dart';
import '../../themes/app_theme.dart';

class InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final bool showOverdueWarning;
  final Function(Invoice, double) onPaymentRecorded;
  final Function(Invoice) onInvoiceFinalized;
  final ScrollController scrollController;
  final bool isLoading;
  final bool hasMore;

  const InvoiceList({
    Key? key,
    required this.invoices,
    this.showOverdueWarning = false,
    required this.onPaymentRecorded,
    required this.onInvoiceFinalized,
    required this.scrollController,
    required this.isLoading,
    required this.hasMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (invoices.isEmpty) {
      return Center(
        child:
            Text(showOverdueWarning ? loc.noOverdueInvoices : loc.noInvoices),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 80,
      ),
      itemCount: invoices.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= invoices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final invoice = invoices[index];
          return InvoiceListItem(
            invoice: invoice,
            showOverdueWarning: showOverdueWarning,
            onPaymentRecorded: onPaymentRecorded,
            onInvoiceFinalized: onInvoiceFinalized,
          );
        } catch (e) {
          // debugPrint('Error rendering invoice item at index $index: $e');
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

  static final _currencyFormat = NumberFormat('#,###.##');

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
        return AppTheme.primaryColor;
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
    final loc = AppLocalizations.of(context)!;

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
                      orElse: () =>
                          <String, dynamic>{'name': 'Unknown Customer'},
                    );
                    final customerName = customer['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${loc.customerInvoice(customerName)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
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
                        invoice.status.localizedName(loc),
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
                    Text(formatLocalizedDate(context, invoice.date.toString())),
                    if (invoice.dueDate != null)
                      Text(
                        formatLocalizedDate(
                            context, invoice.dueDate.toString()),
                        style: TextStyle(
                          color: invoice.isOverdue ? Colors.red : null,
                          fontWeight:
                              invoice.isOverdue ? FontWeight.bold : null,
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
                        '${loc.totalInvoice(_currencyFormat.format(invoice.total))} ${invoice.currency}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (invoice.paidAmount != null && invoice.paidAmount! > 0)
                      Text(
                        '${loc.paidInvoice(_currencyFormat.format(invoice.paidAmount))} ${invoice.currency}',
                        style: const TextStyle(color: Colors.green),
                      ),
                  ],
                ),
                if (invoice.balance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${loc.balanceInvoice(_currencyFormat.format(invoice.balance))} ${invoice.currency}',
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
                        Icon(Icons.warning,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${loc.overdueByInvoice(DateTime.now().difference(invoice.dueDate!).inDays)}',
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
                        child: Text(loc.finalize),
                      ),
                    if (invoice.status != InvoiceStatus.draft &&
                        invoice.status != InvoiceStatus.paid &&
                        invoice.status != InvoiceStatus.cancelled)
                      TextButton(
                        onPressed: () => _showRecordPaymentDialog(context),
                        child: Text(loc.recordPayment),
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
