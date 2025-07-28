import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';
import '../../widgets/unit_conversion_edit_dialog.dart';
import '../../themes/app_theme.dart';

class ManageUnitConversionsScreen extends StatelessWidget {
  const ManageUnitConversionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.unit_conversion_management),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.add_unit_conversion,
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final conversions = provider.unitConversions;
          final units = provider.units;
          if (conversions.isEmpty) {
            return Center(
              child: Text(
                loc.no_unit_conversions,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
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
                      _buildHeaderCell(loc.fromUnit, Icons.swap_horiz, 2),
                      _buildHeaderCell(loc.toUnit, Icons.swap_horiz, 2),
                      _buildHeaderCell(loc.conversionRate, Icons.calculate, 1),
                      _buildHeaderCell(loc.actions, Icons.more_vert, 1),
                    ],
                  ),
                ),
              ),
              // Scrollable Data
              Expanded(
                child: SingleChildScrollView(
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
                        ...conversions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final conversion = entry.value;
                          final fromUnit = units.firstWhere((u) => u.id == conversion.fromUnitId, orElse: () => Unit(id: null, name: '?'));
                          final toUnit = units.firstWhere((u) => u.id == conversion.toUnitId, orElse: () => Unit(id: null, name: '?'));

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
                            child: Row(
                              children: [
                                _buildFromUnitCell(fromUnit),
                                _buildToUnitCell(toUnit),
                                _buildConversionRateCell(conversion, loc),
                                _buildActionsCell(conversion, context, loc),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context),
        icon: const Icon(Icons.add),
        label: Text(loc.add_unit_conversion),
        tooltip: loc.add_unit_conversion,
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

  Widget _buildFromUnitCell(Unit fromUnit) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          fromUnit.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildToUnitCell(Unit toUnit) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          toUnit.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildConversionRateCell(UnitConversion conversion, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '${loc.conversion_rate}: ${conversion.factor}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionsCell(UnitConversion conversion, BuildContext context, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'edit') {
            _showEditDialog(context, conversion: conversion);
          } else if (value == 'delete') {
            _confirmDelete(context, conversion);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18),
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
    );
  }

  Future<void> _showEditDialog(BuildContext context, {UnitConversion? conversion}) async {
    await showDialog(
      context: context,
      builder: (context) => UnitConversionEditDialog(conversion: conversion),
    );
  }

  void _confirmDelete(BuildContext context, UnitConversion conversion) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.delete_unit_conversion),
        content: Text(loc.unit_conversion_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () {
              context.read<InventoryProvider>().deleteUnitConversion(conversion.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.unit_conversion_deleted)),
              );
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
} 