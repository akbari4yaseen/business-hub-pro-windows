import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';

import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/account_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/date_formatters.dart';
import 'dialogs/purchase_form_dialog.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailScreen({Key? key, required this.purchase})
      : super(key: key);

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  static final _currencyFormat = NumberFormat('#,##0.##');

  late Future<List<PurchaseItem>> _itemsFuture;
  late Future<Map<String, dynamic>?> _supplierFuture;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = Future.value([]);
    _supplierFuture = Future.value(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && widget.purchase.id != null) {
      _itemsFuture = context
          .read<PurchaseProvider>()
          .getPurchaseItems(widget.purchase.id);
      _supplierFuture = context
          .read<AccountProvider>()
          .getAccountById(widget.purchase.supplierId);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase.invoiceNumber ?? loc.purchaseDetails),
        actions: _buildAppBarActions(context, loc),
      ),
      body: FutureBuilder<List<PurchaseItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          final additionalCost = widget.purchase.additionalCost;
          final totalCost = widget.purchase.totalAmount + additionalCost;
          final totalQuantity =
              items.fold<double>(0, (sum, i) => sum + i.quantity);
          final additionalCostPerUnit = totalQuantity > 0
              ? (widget.purchase.additionalCost / totalQuantity).toDouble()
              : 0.0;

          return FutureBuilder<Map<String, dynamic>?>(
            future: _supplierFuture,
            builder: (context, supplierSnapshot) {
              final supplier = supplierSnapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSupplierName(loc, supplier),
                    const SizedBox(height: 8),
                    _buildDateRow(context, loc),
                    const SizedBox(height: 24),
                    _buildItemsSection(loc, items, additionalCostPerUnit),
                    const SizedBox(height: 24),
                    _buildTotalsSection(loc, additionalCost, totalCost),
                    if (widget.purchase.notes?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 24),
                      Text(loc.notes, style: _sectionTitleStyle),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(widget.purchase.notes!),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, AppLocalizations loc) {
    return [
      IconButton(
        icon: const Icon(Icons.edit),
        tooltip: loc.editPurchase,
        onPressed: () => _showEditDialog(context),
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        tooltip: loc.deletePurchase,
        onPressed: () => _showDeleteConfirmation(context),
      ),
    ];
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PurchaseFormDialog(purchase: widget.purchase),
    ).then((_) {
      if (!mounted || widget.purchase.id == null) return;
      setState(() {
        _itemsFuture = context
            .read<PurchaseProvider>()
            .getPurchaseItems(widget.purchase.id);
      });
    });
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.deletePurchase),
        content: Text(loc.deletePurchaseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
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
        await context
            .read<PurchaseProvider>()
            .deletePurchase(widget.purchase.id!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.purchaseDeleted)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.error}: $e')),
          );
        }
      }
    }
  }

  Widget _buildSupplierName(
      AppLocalizations loc, Map<String, dynamic>? supplier) {
    return Text(
      '${loc.supplier}: ${supplier?['name'] ?? ''}',
      style: _sectionTitleStyle,
    );
  }

  Widget _buildDateRow(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.date,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              formatLocalizedDateTime(
                  context, widget.purchase.date.toString()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.purchase.currency.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(
    AppLocalizations loc,
    List<PurchaseItem> items,
    double additionalCostPerUnit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.items, style: _sectionTitleStyle),
        const SizedBox(height: 8),
        Card(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.noItemsAdded,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final costPerItem = item.unitPrice + additionalCostPerUnit;
                    return ListTile(
                      title: Text(item.productName ?? 'Unknown Product'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currencyFormat.format(item.quantity)} ${item.unitName ?? 'units'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${loc.price}: ${_currencyFormat.format(item.unitPrice)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${loc.unitCostWithAdditional}: ${_currencyFormat.format(costPerItem)}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        _currencyFormat.format(item.price),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection(
    AppLocalizations loc,
    double additionalCost,
    double totalCost,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalsRow(loc.subtotal, widget.purchase.totalAmount),
            const Divider(),
            _totalsRow(loc.additionalCost, additionalCost),
            const Divider(),
            _totalsRow(
              loc.totalCost,
              totalCost,
              isBold: true,
              color: AppTheme.primaryColor,
            ),
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
        Text(
          label,
          style:
              isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
        Text(
          '\u200E${_currencyFormat.format(amount)} ${widget.purchase.currency}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }

  TextStyle get _sectionTitleStyle =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
}
