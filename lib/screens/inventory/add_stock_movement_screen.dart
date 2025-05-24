import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/date_formatters.dart';
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.newStockMovement),
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _saveStockMovement,
            icon: const Icon(Icons.save),
            tooltip: loc.save,
          ),
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
                  decoration: InputDecoration(
                    labelText: loc.movementType,
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
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(loc.selectProduct),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: _selectedProductId,
                      decoration: InputDecoration(
                        labelText: loc.product,
                        border: const OutlineInputBorder(),
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
                          return loc.selectProduct;
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
                        decoration: InputDecoration(
                          labelText: loc.sourceWarehouse,
                          border: const OutlineInputBorder(),
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
                            return loc.selectSourceWarehouse;
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
                        decoration: InputDecoration(
                          labelText: loc.destinationWarehouse,
                          border: const OutlineInputBorder(),
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
                            return loc.selectDestinationWarehouse;
                          }
                          return null;
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: loc.quantity,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.enterQuantity;
                    }
                    if (double.tryParse(value) == null) {
                      return loc.enterValidNumber;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: loc.reference,
                  ),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: loc.notes,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(loc.expiryDate),
                  subtitle: Text(_expiryDate != null
                      ? formatLocalizedDate(context, _expiryDate.toString())
                      : loc.notSet),
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
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectProduct)),
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
          SnackBar(content: Text('${loc.errorRecordingMovement}: $e')),
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
