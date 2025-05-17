import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/zone.dart' as inventory_models;
import '../../../models/bin.dart' as inventory_models;

class ManageBinsDialog extends StatefulWidget {
  final inventory_models.Zone zone;

  const ManageBinsDialog({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  State<ManageBinsDialog> createState() => _ManageBinsDialogState();
}

class _ManageBinsDialogState extends State<ManageBinsDialog> {
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
      title: Text('Manage Bins - ${widget.zone.name}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Add new bin form
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bin Name',
                        hintText: 'Enter bin name',
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
                        hintText: 'Enter bin description (optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addBin,
                    child: const Text('Add Bin'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // List of existing bins
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  final bins = provider.getZoneBins(widget.zone.id!);
                  if (bins.isEmpty) {
                    return const Center(
                      child: Text(
                        'No bins added yet',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: bins.length,
                    itemBuilder: (context, index) {
                      final bin = bins[index];
                      return Card(
                        child: ListTile(
                          title: Text(bin.name),
                          subtitle: bin.description != null
                              ? Text(bin.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Bin',
                                onPressed: () => _editBin(bin),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Bin',
                                onPressed: () => _deleteBin(bin),
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

  Future<void> _addBin() async {
    if (_formKey.currentState!.validate()) {
      final bin = inventory_models.Bin(
        zoneId: widget.zone.id!,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      await context.read<InventoryProvider>().addBin(bin);
      _nameController.clear();
      _descriptionController.clear();
    }
  }

  Future<void> _editBin(inventory_models.Bin bin) async {
    final nameController = TextEditingController(text: bin.name);
    final descriptionController =
        TextEditingController(text: bin.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bin'),
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
      final updatedBin = inventory_models.Bin(
        id: bin.id,
        zoneId: bin.zoneId,
        name: nameController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
      );
      await context.read<InventoryProvider>().updateBin(updatedBin);
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteBin(inventory_models.Bin bin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bin'),
        content: Text(
            'Are you sure you want to delete the bin "${bin.name}"? This will also delete all stock records in this bin.'),
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
      await context.read<InventoryProvider>().deleteBin(bin.id!);
    }
  }
} 