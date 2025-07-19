import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';
import '../../widgets/unit_conversion_edit_dialog.dart';

class ManageUnitConversionsScreen extends StatelessWidget {
  const ManageUnitConversionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.unit_conversion_management),
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

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            itemCount: conversions.length,
            itemBuilder: (context, index) {
              final conversion = conversions[index];
              final fromUnit = units.firstWhere((u) => u.id == conversion.fromUnitId, orElse: () => Unit(id: null, name: '?'));
              final toUnit = units.firstWhere((u) => u.id == conversion.toUnitId, orElse: () => Unit(id: null, name: '?'));
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text('${fromUnit.name} → ${toUnit.name}'),
                  subtitle: Text('${loc.conversion_rate}: ${conversion.factor}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context, conversion: conversion);
                      } else if (value == 'delete') {
                        _confirmDelete(context, conversion);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: colorScheme.primary),
                          title: Text(loc.edit),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: colorScheme.error),
                          title: Text(loc.delete),
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        child: const Icon(Icons.add),
        tooltip: loc.add_unit_conversion,
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