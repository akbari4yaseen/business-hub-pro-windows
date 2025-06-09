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
  late TextEditingController _referenceNumberController;
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
  bool _isLoadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _referenceNumberController =
        TextEditingController(text: widget.purchase?.referenceNumber ?? '');
    _supplierNameController =
        TextEditingController(text: widget.purchase?.supplierName ?? '');
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
    _referenceNumberController.dispose();
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
    setState(() {
      _items.add(PurchaseItem(
        id: 0,
        purchaseId: widget.purchase?.id ?? 0,
        productId: 0,
        productName: '',
        quantity: 0,
        unitId: 0,
        unitName: '',
        unitPrice: 0,
        price: 0,
        warehouseId: 0,
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

    final inventoryProvider = context.read<InventoryProvider>();
    final unitName = inventoryProvider.getUnitName(unit.unitId);

    setState(() {
      _items[index] = PurchaseItem(
        id: _items[index].id,
        purchaseId: widget.purchase?.id ?? 0,
        productId: product.id,
        productName: product.name,
        quantity: double.tryParse(_quantityControllers[index].text) ?? 0,
        unitId: unit.unitId,
        unitName: unitName,
        unitPrice: double.tryParse(_priceControllers[index].text) ?? 0,
        price: (double.tryParse(_quantityControllers[index].text) ?? 0) *
            (double.tryParse(_priceControllers[index].text) ?? 0),
        warehouseId: 0,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PurchaseProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    // Update unit names before saving
    for (var i = 0; i < _items.length; i++) {
      final unitName = inventoryProvider.getUnitName(_items[i].unitId);
      _items[i] = PurchaseItem(
        id: _items[i].id,
        purchaseId: _items[i].purchaseId,
        productId: _items[i].productId,
        productName: _items[i].productName,
        quantity: _items[i].quantity,
        unitId: _items[i].unitId,
        unitName: unitName,
        unitPrice: _items[i].unitPrice,
        price: _items[i].price,
        warehouseId: _items[i].warehouseId,
        createdAt: _items[i].createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final purchase = Purchase(
      id: widget.purchase?.id ?? 0,
      supplierId: _selectedSupplier?['id'] ?? 0,
      referenceNumber: _referenceNumberController.text,
      supplierName: _selectedSupplier?['name'] ?? _supplierNameController.text,
      date: _selectedDate,
      currency: _selectedCurrency,
      notes: _notesController.text,
      totalAmount: _items.fold(0, (sum, item) => sum + item.price),
      total: _items.fold(0, (sum, item) => sum + item.price),
      paidAmount: 0,
      createdAt: widget.purchase?.createdAt ?? DateTime.now(),
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
                          controller: _referenceNumberController,
                          decoration: InputDecoration(
                            labelText: loc.referenceNumber,
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
                            orElse: () => Product(
                              id: 0,
                              name: '',
                              categoryId: 0,
                              unitId: 0,
                              minimumStock: 0,
                              hasExpiryDate: false,
                              isActive: true,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                          final units = inventoryProvider.units
                              .map((u) => ProductUnit(
                                    id: 0,
                                    productId: product.id,
                                    unitId: u.id!,
                                    isBaseUnit: u.id == product.unitId,
                                    conversionRate: 1,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ))
                              .toList();
                          final unit = units.firstWhere(
                            (u) => u.unitId == item.unitId,
                            orElse: () => ProductUnit(
                              id: 0,
                              productId: 0,
                              unitId: 0,
                              isBaseUnit: true,
                              conversionRate: 1,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${loc.item} ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<Product>(
                                    value: product.id == 0 ? null : product,
                                    decoration: InputDecoration(
                                      labelText: loc.product,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: products.map((p) {
                                      return DropdownMenuItem(
                                        value: p,
                                        child: Text(p.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateItem(index, value, unit);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<
                                            ProductUnit>(
                                          value: unit.unitId == 0 ? null : unit,
                                          decoration: InputDecoration(
                                            labelText: loc.unit,
                                            border: const OutlineInputBorder(),
                                          ),
                                          items: units.map((u) {
                                            return DropdownMenuItem(
                                              value: u,
                                              child: Text(inventoryProvider
                                                  .getUnitName(u.unitId)),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              _updateItem(
                                                  index, product, value);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              _quantityControllers[index],
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
                                  TextFormField(
                                    controller: _priceControllers[index],
                                    decoration: InputDecoration(
                                      labelText: loc.price,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _updateItem(index, product, unit);
                                    },
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
