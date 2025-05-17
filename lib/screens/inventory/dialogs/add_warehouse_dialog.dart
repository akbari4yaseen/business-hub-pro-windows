import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/warehouse.dart';
import '../../../models/zone.dart';
import '../../../models/bin.dart';

class AddWarehouseDialog extends StatefulWidget {
  const AddWarehouseDialog({Key? key}) : super(key: key);

  @override
  _AddWarehouseDialogState createState() => _AddWarehouseDialogState();
}

class _AddWarehouseDialogState extends State<AddWarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ZoneData> _zones = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    for (final zone in _zones) {
      zone.nameController.dispose();
      zone.descriptionController.dispose();
      for (final bin in zone.bins) {
        bin.nameController.dispose();
        bin.descriptionController.dispose();
      }
    }
    super.dispose();
  }

  void _addZone() {
    setState(() {
      _zones.add(ZoneData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Warehouse'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a warehouse name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Zones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ..._zones.map((zone) => ZoneInput(
                    zone: zone,
                    onRemove: () {
                      setState(() {
                        _zones.remove(zone);
                      });
                    },
                  )),
              TextButton.icon(
                onPressed: _addZone,
                icon: const Icon(Icons.add),
                label: const Text('Add Zone'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveWarehouse,
          child: _isSubmitting 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) 
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that all zones and bins have names
    bool isValid = true;
    for (final zone in _zones) {
      if (zone.nameController.text.isEmpty) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All zones must have names')),
        );
        break;
      }
      for (final bin in zone.bins) {
        if (bin.nameController.text.isEmpty) {
          isValid = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All bins must have names')),
          );
          break;
        }
      }
      if (!isValid) break;
    }
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<InventoryProvider>();
      
      // 1. Create warehouse
      final warehouse = Warehouse(
        name: _nameController.text,
        address: _addressController.text,
        description: _descriptionController.text,
      );
      
      final warehouseId = await provider.addWarehouse(warehouse);
      
      // 2. Create zones and bins
      for (final zone in _zones) {
        final newZone = Zone(
          warehouseId: warehouseId,
          name: zone.nameController.text,
          description: zone.descriptionController.text.isNotEmpty 
              ? zone.descriptionController.text 
              : null,
        );
        
        final zoneId = await provider.addZone(newZone);
        
        // Create bins for this zone
        for (final bin in zone.bins) {
          final newBin = Bin(
            zoneId: zoneId,
            name: bin.nameController.text,
            description: bin.descriptionController.text.isNotEmpty 
                ? bin.descriptionController.text 
                : null,
          );
          
          await provider.addBin(newBin);
        }
      }
      
      // Refresh data
      await provider.refreshData();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving warehouse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating warehouse: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class ZoneData {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final List<BinData> bins = [];
}

class BinData {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
}

class ZoneInput extends StatefulWidget {
  final ZoneData zone;
  final VoidCallback onRemove;

  const ZoneInput({
    Key? key,
    required this.zone,
    required this.onRemove,
  }) : super(key: key);

  @override
  _ZoneInputState createState() => _ZoneInputState();
}

class _ZoneInputState extends State<ZoneInput> {
  void _addBin() {
    setState(() {
      widget.zone.bins.add(BinData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.zone.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Zone Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a zone name';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: widget.zone.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Zone Description',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bins',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...widget.zone.bins.map((bin) => BinInput(
                  bin: bin,
                  onRemove: () {
                    setState(() {
                      widget.zone.bins.remove(bin);
                    });
                  },
                )),
            TextButton.icon(
              onPressed: _addBin,
              icon: const Icon(Icons.add),
              label: const Text('Add Bin'),
            ),
          ],
        ),
      ),
    );
  }
}

class BinInput extends StatelessWidget {
  final BinData bin;
  final VoidCallback onRemove;

  const BinInput({
    Key? key,
    required this.bin,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: bin.nameController,
                decoration: const InputDecoration(
                  labelText: 'Bin Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bin name';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
} 