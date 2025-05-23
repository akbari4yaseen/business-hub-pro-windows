import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/stock_movement.dart';
import '../../utils/inventory.dart';

class AddStockMovementScreen extends StatefulWidget {
  const AddStockMovementScreen({Key? key}) : super(key: key);

  @override
  _AddStockMovementScreenState createState() => _AddStockMovementScreenState();
}

class _AddStockMovementScreenState extends State<AddStockMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  MovementType _selectedType = MovementType.stockIn;
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;
  int? _selectedProductId;
  int? _selectedSourceWarehouseId;
  int? _selectedDestinationWarehouseId;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Stock Movement'),
        actions: [
          IconButton(
              onPressed: _isSubmitting ? null : _saveStockMovement,
              icon: Icon(Icons.save)),
        ],
      ),
      backgroundColor: themeProvider.appBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                      child: Text(type.localized(context)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    final products = provider.products;
                    if (products.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'No products available. Please add products to inventory first.'),
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
                if (_selectedType != MovementType.stockIn)
                  Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      final warehouses = provider.warehouses;
                      return DropdownButtonFormField<int>(
                        value: _selectedSourceWarehouseId,
                        decoration: const InputDecoration(
                          labelText: 'Source Warehouse',
                          border: OutlineInputBorder(),
                        ),
                        items: warehouses.map((warehouse) {
                          return DropdownMenuItem<int>(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSourceWarehouseId = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedType != MovementType.stockIn &&
                              value == null) {
                            return 'Please select a source warehouse';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                if (_selectedType != MovementType.stockOut)
                  Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      final warehouses = provider.warehouses;
                      return DropdownButtonFormField<int>(
                        value: _selectedDestinationWarehouseId,
                        decoration: const InputDecoration(
                          labelText: 'Destination Warehouse',
                          border: OutlineInputBorder(),
                        ),
                        items: warehouses.map((warehouse) {
                          return DropdownMenuItem<int>(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDestinationWarehouseId = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedType != MovementType.stockOut &&
                              value == null) {
                            return 'Please select a destination warehouse';
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
                  subtitle:
                      Text(_expiryDate?.toString().split(' ')[0] ?? 'Not set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
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
      ),
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
        sourceWarehouseId: _selectedSourceWarehouseId,
        destinationWarehouseId: _selectedDestinationWarehouseId,
        reference: _referenceController.text.isEmpty
            ? null
            : _referenceController.text,
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
          SnackBar(
              content:
                  Text('Error recording stock movement: [${e.toString()}')),
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
