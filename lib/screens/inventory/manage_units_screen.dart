import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';
import '../../widgets/unit_dialog.dart';
import '../../widgets/unit_conversion_dialog.dart';

class ManageUnitsScreen extends StatelessWidget {
  const ManageUnitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.units),
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

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            itemCount: provider.units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final unit = provider.units[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(unit.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle:
                      unit.description != null ? Text(unit.description!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: loc.unit_conversion,
                        onPressed: () => _showUnitConversionDialog(context, unit),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showUnitDialog(context, unit: unit);
                          } else if (value == 'delete') {
                            _confirmDeleteUnit(context, unit);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(loc.edit),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(loc.delete),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  leading: unit.symbol != null
                      ? CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            unit.symbol!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUnitDialog(context),
        child: const Icon(Icons.add),
        tooltip: loc.add_unit,
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
