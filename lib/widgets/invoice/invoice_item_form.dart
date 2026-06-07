import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';

import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../models/unit.dart';
import '../../themes/app_theme.dart';

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
  double get lineTotal => quantity * unitPrice;

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
  final int index;

  const InvoiceItemForm({
    Key? key,
    required this.formData,
    required this.onRemove,
    required this.onUpdate,
    required this.index,
    this.isPreSale = false,
  }) : super(key: key);

  @override
  State<InvoiceItemForm> createState() => _InvoiceItemFormState();
}

class _InvoiceItemFormState extends State<InvoiceItemForm> {
  static final NumberFormat _amountFormatter = NumberFormat('#,###.###');
  List<Unit> _availableUnits = [];
  double _convertedQuantity = 0;
  String _conversionInfo = '';

  InputDecoration _fieldDecoration({
    required String label,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      suffixText: suffixText,
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lineTotal = widget.formData.lineTotal;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildItemHeader(context, loc, theme, colorScheme, lineTotal),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final products =
                    provider.products.where((p) => p.id != null).toList();

                if (products.isEmpty) {
                  return _buildInfoBanner(
                    icon: Icons.inventory_2_outlined,
                    message: loc.noProductsAvailable,
                    color: colorScheme.errorContainer,
                    textColor: colorScheme.onErrorContainer,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProductStockRow(
                        context, loc, theme, colorScheme, products, provider),
                    const SizedBox(height: 12),
                    _buildQuantityPriceTotalUnitRow(
                        context, loc, theme, colorScheme, lineTotal),
                    if (_conversionInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoBanner(
                        icon: Icons.swap_horiz,
                        message: _conversionInfo,
                        color: colorScheme.secondaryContainer,
                        textColor: colorScheme.onSecondaryContainer,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: widget.formData.descriptionController,
                      decoration: _fieldDecoration(
                        label: loc.descriptionOptional,
                        prefixIcon: Icons.notes_outlined,
                      ),
                      maxLines: 1,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStockRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    List<Product> products,
    InventoryProvider provider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Autocomplete<Map<String, dynamic>>(
            initialValue: widget.formData.selectedProductId != null
                ? TextEditingValue(
                    text: products
                        .firstWhere(
                            (p) => p.id == widget.formData.selectedProductId)
                        .name,
                  )
                : null,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final filteredProducts = textEditingValue.text.isEmpty
                  ? products
                  : products.where((product) => product.name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));

              return filteredProducts.map((product) {
                try {
                  double totalStock = 0.0;
                  try {
                    final stockItems =
                        provider.getCurrentStockForProduct(product.id!);
                    if (stockItems.isNotEmpty) {
                      totalStock = stockItems.fold(0.0, (sum, item) {
                        final qty = item['quantity'] ?? 0.0;
                        return sum +
                            (qty is double
                                ? qty
                                : (double.tryParse(qty.toString()) ?? 0.0));
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
            onSelected: (option) =>
                _onProductSelected(context, loc, provider, products, option),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: _fieldDecoration(
                  label: loc.product,
                  prefixIcon: Icons.search,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseSelectProduct;
                  }
                  return null;
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 280, maxWidth: 480),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final stock = option['stock'] as double;
                        final hasStock = stock > 0;

                        return ListTile(
                          dense: true,
                          title: Text(option['name']),
                          trailing: Text(
                            '${loc.stock}: ${_amountFormatter.format(stock)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasStock
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
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
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: widget.formData.selectedProductId != null
              ? _buildStockPanel(provider, widget.formData.selectedProductId!)
              : _buildStockPlaceholder(loc, colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: widget.formData.selectedProductId != null
              ? _buildWarehouseField(loc, provider, inline: true)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStockPlaceholder(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            loc.availableStock,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockPanel(InventoryProvider provider, int productId) {
    final stock = provider.getCurrentStockForProduct(productId);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isPreSale) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.preSaleWarning,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (stock.isEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              loc.noStockAvailable,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${loc.stock}:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: stock.map((item) {
                  final quantity = item['quantity'];
                  final qtyValue = quantity is double
                      ? quantity
                      : (double.tryParse(quantity.toString()) ?? 0.0);
                  final hasStock = qtyValue > 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasStock
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        '${item['warehouse_name']}: ${_amountFormatter.format(qtyValue)} ${item['unit_name'] ?? ''}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: hasStock
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseField(AppLocalizations loc, InventoryProvider provider,
      {bool inline = false}) {
    final warehouses = provider.warehouses;
    final dropdown = DropdownButtonFormField<int>(
      decoration: _fieldDecoration(
        label: loc.warehouse,
        prefixIcon: Icons.warehouse_outlined,
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

    if (inline) return dropdown;
    return SizedBox(width: 280, child: dropdown);
  }

  Widget _buildQuantityPriceTotalUnitRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    double lineTotal,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: widget.formData.quantityController,
            decoration: _fieldDecoration(
              label: loc.quantity,
              prefixIcon: Icons.numbers,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
            onChanged: (_) {
              setState(() {});
              _updateConversionInfo();
              widget.onUpdate();
            },
            validator: (value) => _validateQuantity(context, loc, value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildUnitField(loc),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: widget.formData.unitPriceController,
            decoration: _fieldDecoration(
              label: loc.unitPrice,
              prefixIcon: Icons.attach_money,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
            onChanged: (_) {
              setState(() {});
              widget.onUpdate();
            },
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
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildLineTotalField(loc, theme, colorScheme, lineTotal),
        ),
      ],
    );
  }

  Widget _buildLineTotalField(
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    double lineTotal,
  ) {
    return InputDecorator(
      decoration: _fieldDecoration(label: loc.subtotal),
      child: Text(
        _amountFormatter.format(lineTotal),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildUnitField(AppLocalizations loc) {
    if (widget.formData.selectedProductId == null || _availableUnits.isEmpty) {
      return InputDecorator(
        decoration: _fieldDecoration(
          label: loc.unit,
          prefixIcon: Icons.straighten_outlined,
        ),
        child: Text(
          '—',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      decoration: _fieldDecoration(
        label: loc.unit,
        prefixIcon: Icons.straighten_outlined,
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
    );
  }

  String? _validateQuantity(
      BuildContext context, AppLocalizations loc, String? value) {
    if (value == null || value.isEmpty) {
      return loc.required;
    }
    final quantity = double.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return loc.invalidQuantity;
    }

    if (widget.formData.selectedProductId != null && !widget.isPreSale) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final stock = provider
          .getCurrentStockForProduct(widget.formData.selectedProductId!);
      final totalStock = stock.fold<double>(
          0, (sum, item) => sum + (item['quantity'] as double));

      final quantityToCheck =
          _convertedQuantity > 0 ? _convertedQuantity : quantity;
      if (quantityToCheck > totalStock) {
        return '${loc.notEnoughStock} (${_amountFormatter.format(totalStock)})';
      }
    }

    return null;
  }

  void _onProductSelected(
    BuildContext context,
    AppLocalizations loc,
    InventoryProvider provider,
    List<Product> products,
    Map<String, dynamic> option,
  ) {
    setState(() {
      widget.formData.selectedProductId = option['id'];
      widget.formData.selectedUnitId = null;
      _availableUnits = [];
      _convertedQuantity = 0;
      _conversionInfo = '';
    });
    final product = products.firstWhere((p) => p.id == option['id']);
    _loadAvailableUnits(provider, product.id!);

    if (product.description != null && product.description!.isNotEmpty) {
      widget.formData.descriptionController.text = product.description!;
    }

    try {
      final stock = provider.getCurrentStockForProduct(product.id!);
      final totalStock = stock.fold<double>(0, (sum, item) {
        final qty = item['quantity'] ?? 0.0;
        return sum +
            (qty is double ? qty : (double.tryParse(qty.toString()) ?? 0.0));
      });

      if (totalStock <= 0 && !widget.isPreSale) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.warningNoStockFor(product.name)),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Silently handle the error
    }
  }

  Widget _buildItemHeader(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    double lineTotal,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${loc.item} ${widget.index + 1}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lineTotal > 0) ...[
            const SizedBox(width: 16),
            Text(
              '${loc.subtotal}: ${_amountFormatter.format(lineTotal)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: widget.onRemove,
            tooltip: loc.remove,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.error,
              backgroundColor:
                  colorScheme.errorContainer.withValues(alpha: 0.35),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String message,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.3),
            ),
          ),
        ],
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
        for (final unit in provider.units) {
          if (unit.id != product.baseUnitId) {
            final factor = provider.getMultiStepConversionFactor(
                unit.id!, product.baseUnitId!);
            if (factor != null) {
              _availableUnits.add(unit);
            }
          }
        }
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
}
