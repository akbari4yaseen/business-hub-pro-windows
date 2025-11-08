import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';

class InvoiceItemFormData {
  final quantityController = TextEditingController(text: '');
  final unitPriceController = TextEditingController(text: '');
  final descriptionController = TextEditingController();
  int? selectedProductId;
  int? selectedUnitId;
  int? selectedWarehouseId;

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice =>
      double.tryParse(unitPriceController.text.replaceAll(',', '')) ?? 0;
  String get description => descriptionController.text;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    descriptionController.dispose();
  }
}

class InvoiceItemForm extends StatefulWidget {
  final InvoiceItemFormData formData;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;
  final bool isPreSale;

  const InvoiceItemForm({
    Key? key,
    required this.formData,
    required this.onRemove,
    required this.onUpdate,
    this.isPreSale = false,
  }) : super(key: key);

  @override
  State<InvoiceItemForm> createState() => _InvoiceItemFormState();
}

class _InvoiceItemFormState extends State<InvoiceItemForm> {
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');
  List<Unit> _availableUnits = [];
  double _convertedQuantity = 0;
  String _conversionInfo = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final products =
                    provider.products.where((p) => p.id != null).toList();

                if (products.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(loc.noProductsAvailable),
                  );
                }

                return Column(
                  children: [
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: widget.formData.selectedProductId != null
                          ? TextEditingValue(
                              text: products
                                  .firstWhere((p) =>
                                      p.id == widget.formData.selectedProductId)
                                  .name,
                            )
                          : null,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // Filter products based on search text if any
                        final filteredProducts = textEditingValue.text.isEmpty
                            ? products
                            : products.where((product) => product.name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));

                        return filteredProducts.map((product) {
                          try {
                            double totalStock = 0.0;

                            try {
                              final stockItems = provider
                                  .getCurrentStockForProduct(product.id!);

                              if (stockItems.isNotEmpty) {
                                // Calculate total stock across all warehouses
                                totalStock = stockItems.fold(0.0, (sum, item) {
                                  final qty = item['quantity'] ?? 0.0;
                                  return sum +
                                      (qty is double
                                          ? qty
                                          : (double.tryParse(qty.toString()) ??
                                              0.0));
                                });
                              }
                            } catch (e) {
                              // Silently handle the error
                            }

                            return {
                              'id': product.id,
                              'name': '${product.name}',
                              'stock': totalStock,
                            };
                          } catch (e) {
                            return {
                              'id': product.id,
                              'name': '${product.name} (Stock N/A)',
                              'stock': 0.0,
                            };
                          }
                        }).toList();
                      },
                      displayStringForOption: (option) => option['name'],
                      onSelected: (option) {
                        setState(() {
                          widget.formData.selectedProductId = option['id'];
                          // Reset unit selection when product changes
                          widget.formData.selectedUnitId = null;
                          _availableUnits = [];
                          _convertedQuantity = 0;
                          _conversionInfo = '';
                        });
                        final product =
                            products.firstWhere((p) => p.id == option['id']);

                        // Load available units for this product
                        _loadAvailableUnits(provider, product.id!);

                        // Set description if the product has one
                        if (product.description != null &&
                            product.description!.isNotEmpty) {
                          widget.formData.descriptionController.text =
                              product.description!;
                        }

                        // Check if we have stock
                        try {
                          final stock =
                              provider.getCurrentStockForProduct(product.id!);
                          final totalStock = stock.fold<double>(0, (sum, item) {
                            final qty = item['quantity'] ?? 0.0;
                            return sum +
                                (qty is double
                                    ? qty
                                    : (double.tryParse(qty.toString()) ?? 0.0));
                          });

                          if (totalStock <= 0 && !widget.isPreSale) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(loc.warningNoStockFor(product.name)),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Silently handle the error
                        }
                      },
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: loc.product,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return loc.pleaseSelectProduct;
                                }
                                return null;
                              },
                            ),
                            if (widget.formData.selectedProductId != null)
                              _buildStockInfo(
                                  provider, widget.formData.selectedProductId!),
                          ],
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['name']),
                                    subtitle: Text(
                                      '${loc.stock}: ${_amountFormatter.format(option['stock'])}',
                                      style: TextStyle(
                                        color: option['stock'] > 0
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Warehouse dropdown
                    if (widget.formData.selectedProductId != null)
                      Consumer<InventoryProvider>(
                        builder: (context, warehouseProvider, child) {
                          final warehouses = warehouseProvider.warehouses;
                          return DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: loc.warehouse,
                            ),
                            value: widget.formData.selectedWarehouseId,
                            items: warehouses.map<DropdownMenuItem<int>>((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                widget.formData.selectedWarehouseId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return loc.pleaseSelectWarehouse;
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    if (widget.formData.selectedProductId != null &&
                        _availableUnits.isNotEmpty)
                      const SizedBox(height: 8),
                    if (widget.formData.selectedProductId != null &&
                        _availableUnits.isNotEmpty)
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: loc.unit,
                        ),
                        value: widget.formData.selectedUnitId,
                        items: _availableUnits.map((unit) {
                          return DropdownMenuItem(
                            value: unit.id,
                            child: Text(unit.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            widget.formData.selectedUnitId = value;
                            _updateConversionInfo();
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return loc.pleaseSelectUnit;
                          }
                          return null;
                        },
                      ),
                    if (_conversionInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _conversionInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.formData.quantityController,
                    decoration: InputDecoration(
                      labelText: loc.quantity,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) {
                      _updateConversionInfo();
                      widget.onUpdate();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.required;
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return loc.invalidQuantity;
                      }

                      // Check if we have enough stock
                      if (widget.formData.selectedProductId != null &&
                          !widget.isPreSale) {
                        final provider = Provider.of<InventoryProvider>(context,
                            listen: false);
                        final stock = provider.getCurrentStockForProduct(
                            widget.formData.selectedProductId!);
                        final totalStock = stock.fold<double>(0,
                            (sum, item) => sum + (item['quantity'] as double));

                        // Use converted quantity for stock check
                        final quantityToCheck = _convertedQuantity > 0
                            ? _convertedQuantity
                            : quantity;
                        if (quantityToCheck > totalStock) {
                          return '${loc.notEnoughStock} (${_amountFormatter.format(totalStock)})';
                        }
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: widget.formData.unitPriceController,
                    decoration: InputDecoration(
                      labelText: loc.unitPrice,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => widget.onUpdate(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.required;
                      }
                      final price = double.tryParse(value.replaceAll(',', ''));
                      if (price == null || price <= 0) {
                        return loc.invalidPrice;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.formData.descriptionController,
              decoration: InputDecoration(
                labelText: loc.descriptionOptional,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  loc.remove,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadAvailableUnits(InventoryProvider provider, int productId) {
    final product = provider.products.firstWhere((p) => p.id == productId);
    if (product.baseUnitId != null) {
      final baseUnit =
          provider.units.firstWhere((u) => u.id == product.baseUnitId);
      setState(() {
        _availableUnits = [baseUnit];
        // Add other units that have conversions to/from base unit
        for (final unit in provider.units) {
          if (unit.id != product.baseUnitId) {
            // Check if there's a conversion path to/from base unit
            final factor = provider.getMultiStepConversionFactor(
                unit.id!, product.baseUnitId!);
            if (factor != null) {
              _availableUnits.add(unit);
            }
          }
        }
        // Set default unit to base unit
        widget.formData.selectedUnitId = product.baseUnitId;
        _updateConversionInfo();
      });
    }
  }

  void _updateConversionInfo() {
    if (widget.formData.selectedProductId == null ||
        widget.formData.selectedUnitId == null ||
        widget.formData.quantity <= 0) {
      setState(() {
        _convertedQuantity = 0;
        _conversionInfo = '';
      });
      return;
    }

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final product = provider.products
        .firstWhere((p) => p.id == widget.formData.selectedProductId);

    if (product.baseUnitId == widget.formData.selectedUnitId) {
      setState(() {
        _convertedQuantity = widget.formData.quantity;
        _conversionInfo = '';
      });
      return;
    }

    final factor = provider.getMultiStepConversionFactor(
        widget.formData.selectedUnitId!, product.baseUnitId!);

    if (factor != null) {
      final converted = widget.formData.quantity * factor;
      final fromUnit = provider.units
          .firstWhere((u) => u.id == widget.formData.selectedUnitId);
      final toUnit =
          provider.units.firstWhere((u) => u.id == product.baseUnitId);

      setState(() {
        _convertedQuantity = converted;
        _conversionInfo =
            '${widget.formData.quantity} ${fromUnit.name} = ${_amountFormatter.format(converted)} ${toUnit.name}';
      });
    } else {
      setState(() {
        _convertedQuantity = widget.formData.quantity;
        _conversionInfo = 'No conversion available';
      });
    }
  }

  Widget _buildStockInfo(InventoryProvider provider, int productId) {
    final stock = provider.getCurrentStockForProduct(productId);
    final loc = AppLocalizations.of(context)!;

    if (widget.isPreSale) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          loc.preSaleWarning,
          style: TextStyle(
              color: Colors.orange.shade700, fontStyle: FontStyle.italic),
        ),
      );
    }

    if (stock.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          loc.noStockAvailable,
          style: TextStyle(
              color: Colors.red.shade700, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            '${loc.availableStock}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...stock.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['warehouse_name']}'),
                    Text(
                      '${_amountFormatter.format(item['quantity'])} ${item['unit_name'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
          const Divider(),
        ],
      ),
    );
  }
}
