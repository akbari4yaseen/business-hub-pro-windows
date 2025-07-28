import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/stock_movement.dart';
import '../../utils/inventory.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

class AddStockMovementDialog extends StatefulWidget {
  final Function(StockMovement) onSave;

  const AddStockMovementDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

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
  DateTime? _selectedDate;
  int? _selectedProductId;
  int? _selectedSourceWarehouseId;
  int? _selectedDestinationWarehouseId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
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
        id: 0, // Replace with the appropriate ID value
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
        date: _selectedDate ?? DateTime.now(),
        createdAt: _selectedDate ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await widget.onSave(movement);
      if (mounted) {
        Navigator.of(context).pop(movement);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Theme(
      data: themeProvider.currentTheme,
      child: Dialog(
        backgroundColor: themeProvider.appBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 500,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.add_circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.newStockMovement,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      DropdownButtonFormField<MovementType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: loc.movementType,
                          border: const OutlineInputBorder(),
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
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<int>(
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
                              ),
                            ],
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
                      Consumer<InventoryProvider>(
                        builder: (context, provider, child) {
                          final products = provider.products;
                          String? unit = '';
                          if (_selectedProductId != null) {
                            try {
                              final product = products.firstWhere(
                                  (p) => p.id == _selectedProductId);
                              unit = provider.getUnitName(product.baseUnitId);
                            } catch (e) {
                              unit = '';
                            }
                          }

                          return TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: loc.quantity,
                              suffix: Text(unit),
                              border: const OutlineInputBorder(),
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
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: loc.date,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await pickLocalizedDate(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        initialValue: _selectedDate != null
                            ? dFormatter.formatLocalizedDate(
                                context, _selectedDate.toString())
                            : loc.notSet,
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: loc.reference,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: loc.notes,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: loc.expiryDate,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await pickLocalizedDate(
                                context: context,
                                initialDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _expiryDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: _expiryDate != null
                              ? dFormatter.formatLocalizedDate(
                                  context, _expiryDate.toString())
                              : loc.notSet,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(loc.cancel),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : _saveStockMovement,
                            child: Text(loc.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
