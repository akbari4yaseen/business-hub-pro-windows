import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/inventory_provider.dart';

class InvoiceItemFormData {
  final quantityController = TextEditingController(text: '');
  final unitPriceController = TextEditingController(text: '');
  final descriptionController = TextEditingController();
  int? selectedProductId;

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

  const InvoiceItemForm({
    Key? key,
    required this.formData,
    required this.onRemove,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<InvoiceItemForm> createState() => _InvoiceItemFormState();
}

class _InvoiceItemFormState extends State<InvoiceItemForm> {
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');
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
                        if (textEditingValue.text.isEmpty) {
                          return products.map((product) {
                            final stock =
                                provider.getCurrentStockForProduct(product.id!);
                            final totalStock = stock.fold<double>(
                                0,
                                (sum, item) =>
                                    sum + (item['quantity'] as double));
                            return {
                              'id': product.id,
                              'name': product.name,
                              'stock': totalStock,
                            };
                          }).toList();
                        }
                        return products.where((product) {
                          return product.name
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        }).map((product) {
                          final stock =
                              provider.getCurrentStockForProduct(product.id!);
                          final totalStock = stock.fold<double>(
                              0,
                              (sum, item) =>
                                  sum + (item['quantity'] as double));
                          return {
                            'id': product.id,
                            'name': product.name,
                            'stock': totalStock,
                          };
                        }).toList();
                      },
                      displayStringForOption: (option) => option['name'],
                      onSelected: (option) {
                        setState(() {
                          widget.formData.selectedProductId = option['id'];
                        });
                        final product =
                            products.firstWhere((p) => p.id == option['id']);

                        // Set description if the product has one
                        if (product.description.isNotEmpty) {
                          widget.formData.descriptionController.text =
                              product.description;
                        }

                        // Check if we have stock
                        final stock =
                            provider.getCurrentStockForProduct(product.id!);
                        final totalStock = stock.fold<double>(0,
                            (sum, item) => sum + (item['quantity'] as double));

                        if (totalStock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${loc.warningNoStockFor(product.name)}'),
                              backgroundColor: Colors.orange,
                            ),
                          );
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
                    onChanged: (_) => widget.onUpdate(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.required;
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return loc.invalidQuantity;
                      }

                      // Check if we have enough stock
                      if (widget.formData.selectedProductId != null) {
                        final provider = Provider.of<InventoryProvider>(context,
                            listen: false);
                        final stock = provider.getCurrentStockForProduct(
                            widget.formData.selectedProductId!);
                        final totalStock = stock.fold<double>(0,
                            (sum, item) => sum + (item['quantity'] as double));

                        if (quantity > totalStock) {
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

  Widget _buildStockInfo(InventoryProvider provider, int productId) {
    final stock = provider.getCurrentStockForProduct(productId);
    final loc = AppLocalizations.of(context)!;

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