import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/warehouse.dart';
import '../../../models/zone.dart' as inventory_models;

class ManageZonesDialog extends StatefulWidget {
  final Warehouse warehouse;

  const ManageZonesDialog({
    Key? key,
    required this.warehouse,
  }) : super(key: key);

  @override
  State<ManageZonesDialog> createState() => _ManageZonesDialogState();
}

class _ManageZonesDialogState extends State<ManageZonesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage Zones - ${widget.warehouse.name}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Add new zone form
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Zone Name',
                        hintText: 'Enter zone name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter zone description (optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addZone,
                    child: const Text('Add Zone'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // List of existing zones
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  final zones = provider.getWarehouseZones(widget.warehouse.id!);
                  if (zones.isEmpty) {
                    return const Center(
                      child: Text(
                        'No zones added yet',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: zones.length,
                    itemBuilder: (context, index) {
                      final zone = zones[index];
                      return Card(
                        child: ListTile(
                          title: Text(zone.name),
                          subtitle: zone.description != null
                              ? Text(zone.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.grid_4x4),
                                tooltip: 'Manage Bins',
                                onPressed: () => _manageBins(zone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Zone',
                                onPressed: () => _editZone(zone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Zone',
                                onPressed: () => _deleteZone(zone),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _addZone() async {
    if (_formKey.currentState!.validate()) {
      final zone = inventory_models.Zone(
        warehouseId: widget.warehouse.id!,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      await context.read<InventoryProvider>().addZone(zone);
      _nameController.clear();
      _descriptionController.clear();
    }
  }

  Future<void> _editZone(inventory_models.Zone zone) async {
    final nameController = TextEditingController(text: zone.name);
    final descriptionController =
        TextEditingController(text: zone.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedZone = inventory_models.Zone(
        id: zone.id,
        warehouseId: zone.warehouseId,
        name: nameController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
      );
      await context.read<InventoryProvider>().updateZone(updatedZone);
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteZone(inventory_models.Zone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text(
            'Are you sure you want to delete the zone "${zone.name}"? This will also delete all bins in this zone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<InventoryProvider>().deleteZone(zone.id!);
    }
  }

  Future<void> _manageBins(inventory_models.Zone zone) async {
    // TODO: Implement manage bins dialog
  }
} 