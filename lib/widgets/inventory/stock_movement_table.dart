import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/stock_movement.dart';
import '../../utils/date_formatters.dart';
import '../../utils/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../../themes/app_theme.dart';
import '../inventory/movement_details_sheet.dart';
import '../auth_widget.dart';

class StockMovementTable extends StatelessWidget {
  final List<StockMovement> movements;
  final ScrollController scrollController;
  final bool isLoading;
  final bool hasMore;
  final Function(StockMovement) onDelete;
  final Widget? filters;

  const StockMovementTable({
    Key? key,
    required this.movements,
    required this.scrollController,
    required this.isLoading,
    required this.hasMore,
    required this.onDelete,
    this.filters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              loc.noMovementsFound,
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

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Filters Section
          if (filters != null) filters!,
          // Data Table
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
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
                // Table Header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                              Icon(Icons.calendar_today,
                                  size: 18, color: AppTheme.primaryColor),
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
                      _buildHeaderCell(loc.product, Icons.inventory, 2),
                      _buildHeaderCell(loc.type, Icons.category, 1),
                      _buildHeaderCell(loc.quantity, Icons.scale, 1),
                      _buildHeaderCell(loc.from, Icons.location_on, 1),
                      _buildHeaderCell(loc.to, Icons.location_on, 1),
                      _buildHeaderCell(loc.actions, Icons.more_vert, 1),
                    ],
                  ),
                ),
                // Table Rows
                ...movements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final movement = entry.value;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.03)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade100,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _showMovementDetails(context, movement),
                      onLongPress: () =>
                          _showMovementDetails(context, movement),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          _buildDateCell(movement.date.toString(), context),
                          _buildProductCell(movement.productId, context),
                          _buildTypeCell(movement, context),
                          _buildQuantityCell(movement, context),
                          _buildFromCell(movement, context),
                          _buildToCell(movement, context),
                          _buildActionsCell(movement, context),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // Loading indicator for pagination
          if (hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
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
          formatLocalizedDateTime(context, date),
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

  Widget _buildProductCell(int productId, BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            final product = provider.products.firstWhere(
              (p) => p.id == productId,
              orElse: () => throw Exception('Product not found'),
            );
            return Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeCell(StockMovement movement, BuildContext context) {
    final color = _getMovementTypeColor(movement.type);
    final icon = _getMovementTypeIcon(movement.type);

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  movement.type.localized(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityCell(StockMovement movement, BuildContext context) {
    final numberFormatter = NumberFormat('#,###.##');

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            final product = provider.products.firstWhere(
              (p) => p.id == movement.productId,
              orElse: () => throw Exception('Product not found'),
            );
            final unitName = provider.getUnitName(product.baseUnitId);

            return Text(
              '${numberFormatter.format(movement.quantity)} $unitName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFromCell(StockMovement movement, BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            String sourceLocation = '-';
            if (movement.sourceWarehouseId != null) {
              final sourceWarehouse = provider.warehouses.firstWhere(
                (w) => w.id == movement.sourceWarehouseId,
                orElse: () => throw Exception('Warehouse not found'),
              );
              sourceLocation = sourceWarehouse.name;
            }

            return Text(
              sourceLocation,
              style: const TextStyle(
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }

  Widget _buildToCell(StockMovement movement, BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            String destinationLocation = loc.notAvailable;
            if (movement.destinationWarehouseId != null) {
              final destWarehouse = provider.warehouses.firstWhere(
                (w) => w.id == movement.destinationWarehouseId,
                orElse: () => throw Exception('Warehouse not found'),
              );
              destinationLocation = destWarehouse.name;
            }

            return Text(
              destinationLocation,
              style: const TextStyle(
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionsCell(StockMovement movement, BuildContext context) {
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
              _showMovementDetails(context, movement);
              break;
            case 'delete':
              _showDeleteConfirmation(context, movement);
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
    );
  }

  Color _getMovementTypeColor(MovementType type) {
    switch (type) {
      case MovementType.stockIn:
        return Colors.green;
      case MovementType.stockOut:
        return Colors.red;
      case MovementType.transfer:
        return AppTheme.primaryColor;
    }
  }

  IconData _getMovementTypeIcon(MovementType type) {
    switch (type) {
      case MovementType.stockIn:
        return Icons.add_circle;
      case MovementType.stockOut:
        return Icons.remove_circle;
      case MovementType.transfer:
        return Icons.swap_horiz;
    }
  }

  void _showMovementDetails(BuildContext context, StockMovement movement) {
    final loc = AppLocalizations.of(context)!;
    final numberFormatter = NumberFormat('#,###.##');

    showDialog(
      context: context,
      builder: (context) => Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final product = provider.products.firstWhere(
            (p) => p.id == movement.productId,
            orElse: () => throw Exception('Product not found'),
          );
          final unitName = provider.getUnitName(product.baseUnitId);

          String sourceLocation = loc.notAvailable;
          if (movement.sourceWarehouseId != null) {
            final sourceWarehouse = provider.warehouses.firstWhere(
              (w) => w.id == movement.sourceWarehouseId,
              orElse: () => throw Exception('Warehouse not found'),
            );
            sourceLocation = sourceWarehouse.name;
          }

          String destinationLocation = loc.notAvailable;
          if (movement.destinationWarehouseId != null) {
            final destWarehouse = provider.warehouses.firstWhere(
              (w) => w.id == movement.destinationWarehouseId,
              orElse: () => throw Exception('Warehouse not found'),
            );
            destinationLocation = destWarehouse.name;
          }

          return MovementDetailsSheet(
            movement: movement,
            product: product,
            sourceLocation: sourceLocation,
            destinationLocation: destinationLocation,
            unitName: unitName,
            numberFormatter: numberFormatter,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StockMovement movement) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AuthWidget(
        actionReason: loc.deleteStockMovementAuthMessage,
        onAuthenticated: () {
          Navigator.of(context).pop(); // Close AuthWidget
          showDialog(
            context: context,
            builder: (confirmCtx) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AlertDialog(
                  title: Text(loc.confirmDelete),
                  content: Text(loc.confirmDeleteStockMovement),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(confirmCtx).pop(),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(confirmCtx).pop();
                        onDelete(movement);
                      },
                      child: Text(
                        loc.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
