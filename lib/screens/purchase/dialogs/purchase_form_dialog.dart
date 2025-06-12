import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../models/purchase.dart';
import '../../../models/purchase_item.dart';
import '../../../models/product.dart';
import '../../../models/product_unit.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../constants/currencies.dart';

class PurchaseFormDialog extends StatefulWidget {
  final Purchase? purchase;

  const PurchaseFormDialog({
    Key? key,
    this.purchase,
  }) : super(key: key);

  @override
  State<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceNumberController;
  late TextEditingController _supplierNameController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  final List<PurchaseItem> _items = [];

  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];
  String _selectedCurrency = 'AFN';
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoadingSuppliers = false;
  bool _isLoadingWarehouses = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController =
        TextEditingController(text: widget.purchase?.invoiceNumber ?? '');
    _supplierNameController = TextEditingController(
        text: widget.purchase?.supplierId.toString() ?? '');
    _dateController = TextEditingController(
        text: widget.purchase?.date.toIso8601String().split('T')[0] ??
            DateTime.now().toIso8601String().split('T')[0]);
    _notesController =
        TextEditingController(text: widget.purchase?.notes ?? '');
    _selectedDate = widget.purchase?.date ?? DateTime.now();
    _selectedCurrency = widget.purchase?.currency ?? 'AFN';

    if (widget.purchase != null) {
      _loadPurchaseItems();
    }

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inventoryProvider = context.read<InventoryProvider>();
      if (!inventoryProvider.units.isNotEmpty) {
        await inventoryProvider.initialize();
      }
      _loadSuppliers();
      _loadWarehouses();
    });
  }

  Future<void> _loadSuppliers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSuppliers = true;
    });

    try {
      final accountProvider = context.read<AccountProvider>();
      await accountProvider.loadAccounts();
      if (!mounted) return;

      final suppliers = accountProvider.getAccountsByType('supplier');
      if (!mounted) return;

      setState(() {
        _suppliers = suppliers;
        if (widget.purchase != null) {
          _selectedSupplier = suppliers.firstWhere(
            (s) => s['id'] == widget.purchase!.supplierId,
            orElse: () => suppliers.first,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  Future<void> _loadWarehouses() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWarehouses = true;
    });

    try {
      final inventoryProvider = context.read<InventoryProvider>();
      await inventoryProvider.initialize(); // This will load warehouses
      if (!mounted) return;

      setState(() {
        _warehouses = inventoryProvider.warehouses.map((w) => w.toMap()).toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWarehouses = false;
        });
      }
    }
  }

  Future<void> _loadPurchaseItems() async {
    if (!mounted) return;

    final provider = context.read<PurchaseProvider>();
    final items = await provider.getPurchaseItems(widget.purchase!.id);
    if (!mounted) return;

    setState(() {
      _items.addAll(items);
      for (var item in _items) {
        _quantityControllers
            .add(TextEditingController(text: item.quantity.toString()));
        _priceControllers
            .add(TextEditingController(text: item.price.toString()));
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _supplierNameController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _addItem() {
    final inventoryProvider = context.read<InventoryProvider>();
    final products = inventoryProvider.products;
    final loc = AppLocalizations.of(context)!;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noProductsAvailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final product = products.first;
    final productUnits = inventoryProvider.getProductUnits(product.id);
    
    if (productUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.no_units),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _items.add(PurchaseItem(
        id: 0,
        purchaseId: widget.purchase?.id ?? 0,
        productId: product.id,
        quantity: 0,
        unitId: productUnits.first.unitId,
        unitPrice: 0,
        warehouseId: _warehouses.isNotEmpty ? _warehouses.first['id'] : 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _quantityControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _quantityControllers[index].dispose();
      _quantityControllers.removeAt(index);
      _priceControllers[index].dispose();
      _priceControllers.removeAt(index);
    });
  }

  void _updateItem(int index, Product product, ProductUnit unit) {
    if (!mounted) return;

    setState(() {
      _items[index] = PurchaseItem(
        id: _items[index].id,
        purchaseId: widget.purchase?.id ?? 0,
        productId: product.id,
        quantity: double.tryParse(_quantityControllers[index].text) ?? 0,
        unitId: unit.unitId,
        unitPrice: double.tryParse(_priceControllers[index].text) ?? 0,
        warehouseId: 0,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _updateWarehouse(int index, int warehouseId) {
    setState(() {
      _items[index] = PurchaseItem(
        id: _items[index].id,
        purchaseId: _items[index].purchaseId,
        productId: _items[index].productId,
        quantity: _items[index].quantity,
        unitId: _items[index].unitId,
        unitPrice: _items[index].unitPrice,
        warehouseId: warehouseId,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that all items have valid foreign key references
    for (var item in _items) {
      if (item.productId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.selectProduct),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.unitId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unit),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.warehouseId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.warehouse),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final provider = context.read<PurchaseProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    // Update items before saving
    for (var i = 0; i < _items.length; i++) {
      _items[i] = PurchaseItem(
        id: _items[i].id,
        purchaseId: _items[i].purchaseId,
        productId: _items[i].productId,
        quantity: _items[i].quantity,
        unitId: _items[i].unitId,
        unitPrice: _items[i].unitPrice,
        warehouseId: _items[i].warehouseId,
        createdAt: _items[i].createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final purchase = Purchase(
      supplierId: _selectedSupplier?['id'] ?? 0,
      invoiceNumber: _invoiceNumberController.text,
      date: _selectedDate,
      currency: _selectedCurrency,
      notes: _notesController.text,
      totalAmount: _items.fold(0, (sum, item) => sum + item.price),
      paidAmount: 0,
      dueDate: _selectedDate.add(Duration(days: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.purchase == null) {
        await provider.addPurchase(purchase, _items);
      } else {
        await provider.updatePurchase(purchase, _items);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final products = inventoryProvider.products;
        return AlertDialog(
          title: Text(
              widget.purchase == null ? loc.addPurchase : loc.editPurchase),
          content: _isLoadingSuppliers
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _invoiceNumberController,
                          decoration: InputDecoration(
                            labelText: loc.invoice,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.requiredField;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _suppliers;
                            }
                            return _suppliers.where((supplier) {
                              return supplier['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase());
                            });
                          },
                          displayStringForOption: (option) => option['name'],
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: loc.supplier,
                                border: const OutlineInputBorder(),
                                suffixIcon: _isLoadingSuppliers
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return loc.requiredField;
                                }
                                return null;
                              },
                            );
                          },
                          onSelected: (Map<String, dynamic> supplier) {
                            setState(() {
                              _selectedSupplier = supplier;
                              _supplierNameController.text = supplier['name'];
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option['name']),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: loc.date,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: loc.currency,
                            border: const OutlineInputBorder(),
                          ),
                          items: currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                            }
                          },
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.items,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add),
                              label: Text(loc.addItem),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_items.length, (index) {
                          final item = _items[index];
                          final product = products.firstWhere(
                            (p) => p.id == item.productId,
                            orElse: () => products.first,
                          );
                          
                          // Get product units for the selected product
                          final productUnits = inventoryProvider.getProductUnits(product.id);
                          final unit = productUnits.firstWhere(
                            (u) => u.unitId == item.unitId,
                            orElse: () => productUnits.first,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${loc.item} ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<int>(
                                    value: product.id,
                                    decoration: InputDecoration(
                                      labelText: loc.product,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: products.map((p) {
                                      return DropdownMenuItem(
                                        value: p.id,
                                        child: Text(p.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        final selectedProduct = products.firstWhere((p) => p.id == value);
                                        final selectedProductUnits = inventoryProvider.getProductUnits(selectedProduct.id);
                                        final selectedUnit = selectedProductUnits.first;
                                        _updateItem(index, selectedProduct, selectedUnit);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          value: unit.unitId,
                                          decoration: InputDecoration(
                                            labelText: loc.unit,
                                            border: const OutlineInputBorder(),
                                          ),
                                          items: productUnits.map((u) {
                                            return DropdownMenuItem(
                                              value: u.unitId,
                                              child: Text(inventoryProvider.getUnitName(u.unitId)),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              final selectedUnit = productUnits.firstWhere((u) => u.unitId == value);
                                              _updateItem(index, product, selectedUnit);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _quantityControllers[index],
                                          decoration: InputDecoration(
                                            labelText: loc.quantity,
                                            border: const OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            _updateItem(index, product, unit);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceControllers[index],
                                          decoration: InputDecoration(
                                            labelText: loc.unitPrice,
                                            border: const OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            _updateItem(index, product, unit);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<Map<String, dynamic>>(
                                          value: _warehouses.firstWhere(
                                            (w) => w['id'] == item.warehouseId,
                                            orElse: () => _warehouses.first,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: loc.warehouse,
                                            border: const OutlineInputBorder(),
                                          ),
                                          items: _warehouses.map((w) {
                                            return DropdownMenuItem(
                                              value: w,
                                              child: Text(w['name']),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              _updateWarehouse(index, value['id']);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: _isLoadingSuppliers ? null : _savePurchase,
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }
}
