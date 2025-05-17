import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';
import '../../../models/warehouse.dart';
import '../../../models/zone.dart';
import '../../../models/bin.dart';

class AddStockMovementDialog extends StatefulWidget {
  const AddStockMovementDialog({Key? key}) : super(key: key);

  @override
  _AddStockMovementDialogState createState() => _AddStockMovementDialogState();
}

class _AddStockMovementDialogState extends State<AddStockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  MovementType _selectedType = MovementType.stockIn;
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;
  int? _selectedProductId;
  int? _selectedSourceBinId;
  int? _selectedDestinationBinId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Stock Movement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MovementType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Movement Type',
                ),
                items: MovementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              
              // Product Selection
              Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  final products = provider.products;
                  
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No products available. Please add products to inventory first.'),
                    );
                  }
                  
                  return DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem<int>(
                        value: product.id,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Source Bin (for Stock Out or Transfer)
              if (_selectedType != MovementType.stockIn)
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    // Filter bins that have the selected product
                    final bins = _selectedProductId != null
                        ? provider.currentStock
                            .where((item) => item['product_id'] == _selectedProductId)
                            .map((item) => {
                              'bin_id': item['bin_id'], 
                              'name': '${item['warehouse_name']} > ${item['zone_name']} > ${item['bin_name']}',
                              'quantity': item['quantity'],
                            })
                            .toList()
                        : [];
                    
                    return DropdownButtonFormField<int>(
                      value: _selectedSourceBinId,
                      decoration: const InputDecoration(
                        labelText: 'Source Location',
                        border: OutlineInputBorder(),
                      ),
                      items: bins.map((bin) {
                        return DropdownMenuItem<int>(
                          value: bin['bin_id'] as int,
                          child: Text('${bin['name']} (${bin['quantity']} units)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSourceBinId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedType != MovementType.stockIn && value == null) {
                          return 'Please select a source location';
                        }
                        return null;
                      },
                    );
                  },
                ),
                
              const SizedBox(height: 16),
              
              // Destination Bin (for Stock In or Transfer)
              if (_selectedType != MovementType.stockOut)
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    // Get all available bins
                    final bins = provider.bins
                        .map((bin) {
                          Zone zone = provider.zones.firstWhere(
                            (zone) => zone.id == bin.zoneId,
                            orElse: () => Zone(
                              warehouseId: 0, 
                              name: 'Unknown Zone',
                              description: null,
                            ),
                          );
                          
                          Warehouse warehouse = provider.warehouses.firstWhere(
                            (warehouse) => warehouse.id == zone.warehouseId,
                            orElse: () => Warehouse(
                              name: 'Unknown Warehouse', 
                              address: '',
                            ),
                          );
                          
                          return {
                            'bin_id': bin.id, 
                            'name': '${warehouse.name} > ${zone.name} > ${bin.name}',
                          };
                        })
                        .toList();
                    
                    return DropdownButtonFormField<int>(
                      value: _selectedDestinationBinId,
                      decoration: const InputDecoration(
                        labelText: 'Destination Location',
                        border: OutlineInputBorder(),
                      ),
                      items: bins.map((bin) {
                        return DropdownMenuItem<int>(
                          value: bin['bin_id'] as int,
                          child: Text(bin['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDestinationBinId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedType != MovementType.stockOut && value == null) {
                          return 'Please select a destination location';
                        }
                        return null;
                      },
                    );
                  },
                ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference',
                ),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(_expiryDate?.toString().split(' ')[0] ?? 'Not set'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _expiryDate = date;
                      });
                    }
                  },
                ),
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
          onPressed: _isSubmitting ? null : _saveStockMovement,
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
  
  Future<void> _saveStockMovement() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final movement = StockMovement(
        productId: _selectedProductId!,
        quantity: double.parse(_quantityController.text),
        type: _selectedType,
        sourceBinId: _selectedSourceBinId,
        destinationBinId: _selectedDestinationBinId,
        reference: _referenceController.text.isEmpty ? null : _referenceController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        expiryDate: _expiryDate,
        createdAt: DateTime.now(),
      );

      await context.read<InventoryProvider>().recordStockMovement(movement);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error recording stock movement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording stock movement: ${e.toString()}')),
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