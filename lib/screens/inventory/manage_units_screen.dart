import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';

class ManageUnitsScreen extends StatelessWidget {
  const ManageUnitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Units'),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.units.isEmpty) {
            return const Center(
              child: Text('No units found. Add your first unit.'),
            );
          }
          return ListView.builder(
            itemCount: provider.units.length,
            itemBuilder: (context, index) {
              final unit = provider.units[index];
              return ListTile(
                title: Text(unit.name),
                subtitle: unit.description != null ? Text(unit.description!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unit.symbol != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          unit.symbol!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editUnit(context, unit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDeleteUnit(context, unit),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUnitDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Unit',
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    final descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Unit Name'),
            ),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: 'Symbol (Optional)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final unit = Unit(
                  name: nameController.text,
                  symbol: symbolController.text.isNotEmpty ? symbolController.text : null,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                );
                context.read<InventoryProvider>().addUnit(unit);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editUnit(BuildContext context, Unit unit) {
    final nameController = TextEditingController(text: unit.name);
    final symbolController = TextEditingController(text: unit.symbol);
    final descriptionController = TextEditingController(text: unit.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Unit Name'),
            ),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: 'Symbol (Optional)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedUnit = Unit(
                  id: unit.id,
                  name: nameController.text,
                  symbol: symbolController.text.isNotEmpty ? symbolController.text : null,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                );
                context.read<InventoryProvider>().updateUnit(updatedUnit);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUnit(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete "${unit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<InventoryProvider>().deleteUnit(unit.id!);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 