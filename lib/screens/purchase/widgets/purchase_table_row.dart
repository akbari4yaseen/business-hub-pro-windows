import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/purchase.dart';
import '../../../providers/purchase_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../utils/date_formatters.dart';

final _amountFormatter = NumberFormat('#,##0.##');

class PurchaseTableRow extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  const PurchaseTableRow({
    Key? key,
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
  }) : super(key: key);

  @override
  State<PurchaseTableRow> createState() => _PurchaseTableRowState();
}

class _PurchaseTableRowState extends State<PurchaseTableRow> {
  List<PurchaseItem> _items = [];
  Map<String, dynamic>? _supplier;
  bool _isLoadingItems = true;
  bool _isLoadingSupplier = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.purchase['id'] != null) {
      _loadItems();
      _loadSupplier();
    } else {
      setState(() {
        _isLoadingItems = false;
        _isLoadingSupplier = false;
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      final purchaseId = widget.purchase['id'] as int?;
      if (purchaseId != null) {
        final items =
            await context.read<PurchaseProvider>().getPurchaseItems(purchaseId);
        if (mounted) {
          setState(() {
            _items = items;
            _isLoadingItems = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingItems = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _loadSupplier() async {
    try {
      // The supplier name is already included in the purchase data from the JOIN
      if (mounted) {
        setState(() {
          _supplier = {
            'name': widget.purchase['supplier_name']?.toString() ??
                'Unknown Supplier'
          };
          _isLoadingSupplier = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSupplier = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Date
        SizedBox(
          width: 90,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              formatLocalizedDateTime(
                  context,
                  (widget.purchase['date'] as String?) ??
                      DateTime.now().toIso8601String()),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Supplier
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.purchase['supplier_name']?.toString() ??
                  (_isLoadingSupplier ? 'Loading...' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Invoice Number
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.purchase['invoice_number']?.toString() ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Total Amount
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '\u200E${_amountFormatter.format((widget.purchase['total_amount'] as num?)?.toDouble() ?? 0.0)} ${widget.purchase['currency'] ?? ''}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        // Items
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoadingItems
                ? Text(
                    'Loading...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                : _items.isNotEmpty
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _items.first.productName ?? 'Unknown',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_items.length > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        'No items',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
          ),
        ),
        // Actions
        Expanded(
          flex: 1,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            tooltip: loc.actions,
            padding: EdgeInsets.zero,
            onSelected: (value) {
              switch (value) {
                case 'details':
                  widget.onDetails();
                  break;
                case 'edit':
                  widget.onEdit();
                  break;
                case 'delete':
                  widget.onDelete();
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
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(loc.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Text(loc.delete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
