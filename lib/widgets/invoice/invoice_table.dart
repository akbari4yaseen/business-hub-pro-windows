import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'record_payment_dialog.dart';
import '../../models/invoice.dart';
import '../../utils/date_formatters.dart';
import '../../utils/invoice.dart';
import '../../screens/invoice/invoice_detail_screen.dart';
import '../../providers/account_provider.dart';
import '../../themes/app_theme.dart';

class InvoiceTable extends StatelessWidget {
  final List<Invoice> invoices;
  final bool showOverdueWarning;
  final Function(Invoice, double) onPaymentRecorded;
  final Function(Invoice) onInvoiceFinalized;
  final ScrollController scrollController;
  final bool isLoading;
  final bool hasMore;

  const InvoiceTable({
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              showOverdueWarning ? loc.noOverdueInvoices : loc.noInvoices,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'VazirBold',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Fixed Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          loc.date,
                          style: TextStyle(
                            fontFamily: 'VazirBold',
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHeaderCell(loc.invoiceNumber, Icons.receipt, 1),
                _buildHeaderCell(loc.customer, Icons.person, 2),
                _buildHeaderCell(loc.status, Icons.info, 1),
                _buildHeaderCell(loc.total, Icons.attach_money, 1),
                _buildHeaderCell(loc.actions, Icons.more_vert, 1),
              ],
            ),
          ),
        ),
        // Scrollable Data
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Rows
                  ...invoices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final invoice = entry.value;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: index.isEven 
                            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.03)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showInvoiceDetails(context, invoice),
                        onLongPress: () => _showInvoiceDetails(context, invoice),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            _buildDateCell(invoice.date.toString(), context),
                            _buildInvoiceNumberCell(invoice.invoiceNumber),
                            _buildCustomerCell(invoice.accountId, context),
                            _buildStatusCell(invoice, context),
                            _buildTotalCell(invoice),
                            _buildActionsCell(invoice, context),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  // Loading indicator for pagination
                  if (hasMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, IconData icon, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'VazirBold',
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCell(String date, BuildContext context) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          formatLocalizedDate(context, date),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInvoiceNumberCell(String invoiceNumber) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          invoiceNumber,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCustomerCell(int accountId, BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Consumer<AccountProvider>(
          builder: (context, accountProvider, child) {
            final customer = accountProvider.accounts.firstWhere(
              (c) => c['id'] == accountId,
              orElse: () => <String, dynamic>{'name': 'Unknown Customer'},
            );
            final customerName = customer['name'];
            return Text(
              customerName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCell(Invoice invoice, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(invoice.status);
    
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            invoice.status.localizedName(loc),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCell(Invoice invoice) {
    final currencyFormat = NumberFormat('#,###.##');
    
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '${currencyFormat.format(invoice.total)} ${invoice.currency}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Invoice invoice, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          switch (value) {
            case 'details':
              _showInvoiceDetails(context, invoice);
              break;
            case 'finalize':
              if (invoice.status == InvoiceStatus.draft) {
                onInvoiceFinalized(invoice);
              }
              break;
            case 'payment':
              if (invoice.status != InvoiceStatus.draft &&
                  invoice.status != InvoiceStatus.paid &&
                  invoice.status != InvoiceStatus.cancelled) {
                _showRecordPaymentDialog(context, invoice);
              }
              break;
            default:
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                const Icon(Icons.info, size: 18),
                const SizedBox(width: 12),
                Text(loc.details),
              ],
            ),
          ),
          if (invoice.status == InvoiceStatus.draft)
            PopupMenuItem(
              value: 'finalize',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(loc.finalize),
                ],
              ),
            ),
          if (invoice.status != InvoiceStatus.draft &&
              invoice.status != InvoiceStatus.paid &&
              invoice.status != InvoiceStatus.cancelled)
            PopupMenuItem(
              value: 'payment',
              child: Row(
                children: [
                  Icon(Icons.payment, size: 18, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(loc.recordPayment),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
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

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        invoice: invoice,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }
} 