import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';
import '../../widgets/unit_dialog.dart';
import '../../widgets/unit_conversion_dialog.dart';
import '../../themes/app_theme.dart';

class ManageUnitsScreen extends StatelessWidget {
  const ManageUnitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.units),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.addUnit,
            onPressed: () => _showUnitDialog(context),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 80, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    loc.no_units,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
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
                      _buildHeaderCell(loc.unitName, Icons.inbox, 2),
                      _buildHeaderCell(loc.description, Icons.description, 3),
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
                        ...provider.units.asMap().entries.map((entry) {
                          final index = entry.key;
                          final unit = entry.value;

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
                                _buildUnitNameCell(unit),
                                _buildDescriptionCell(unit),
                                _buildActionsCell(unit, context, loc),
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
        onPressed: () => _showUnitDialog(context),
        icon: const Icon(Icons.add),
        label: Text(loc.addUnit),
        tooltip: loc.addUnit,
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

  Widget _buildUnitNameCell(Unit unit) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          unit.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDescriptionCell(Unit unit) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          unit.description ?? '-',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Unit unit, BuildContext context, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            tooltip: loc.unit_conversion,
            onPressed: () => _showUnitConversionDialog(context, unit),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            tooltip: loc.actions,
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') {
                _showUnitDialog(context, unit: unit);
              } else if (value == 'delete') {
                _confirmDeleteUnit(context, unit);
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
        ],
      ),
    );
  }

  void _showUnitDialog(BuildContext context, {Unit? unit}) {
    showDialog(
      context: context,
      builder: (context) => UnitDialog(unit: unit),
    );
  }

  void _showUnitConversionDialog(BuildContext context, Unit fromUnit) {
    final provider = context.read<InventoryProvider>();
    final otherUnits = provider.units.where((u) => u.id != fromUnit.id).toList();

    if (otherUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.no_units),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unit_conversion),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherUnits.length,
            itemBuilder: (context, index) {
              final toUnit = otherUnits[index];
              return ListTile(
                title: Text(toUnit.name),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => UnitConversionDialog(
                      fromUnit: fromUnit,
                      toUnit: toUnit,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUnit(BuildContext context, Unit unit) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.delete_unit),
        content: Text(loc.unit_delete_confirm(unit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<InventoryProvider>().deleteUnit(unit.id!);
              Navigator.of(context).pop();
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
