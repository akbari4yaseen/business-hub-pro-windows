import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../models/purchase.dart';
import '../../../models/purchase_item.dart';
import '../../../models/product.dart';
import '../../../models/unit.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../constants/currencies.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;

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
  bool _isInitialized = false;

  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _productNameControllers = [];
  String _selectedCurrency = 'AFN';
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoadingSuppliers = false;
  late TextEditingController _additionalCostController;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController =
        TextEditingController(text: widget.purchase?.invoiceNumber ?? '');
    _supplierNameController = TextEditingController();
    _dateController = TextEditingController();
    _notesController =
        TextEditingController(text: widget.purchase?.notes ?? '');
    _selectedDate = widget.purchase?.date ?? DateTime.now();
    _selectedCurrency = widget.purchase?.currency ?? 'AFN';
    _additionalCostController = TextEditingController(
        text: widget.purchase?.additionalCost != null
            ? widget.purchase!.additionalCost.toString()
            : '0');

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _dateController.text = dFormatter.formatLocalizedDateTime(context,
          widget.purchase?.date.toString() ?? DateTime.now().toString());
      _isInitialized = true;
    }
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
          // Set the supplier name controller text
          if (_selectedSupplier != null) {
            _supplierNameController.text = _selectedSupplier!['name'];
          }
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

    final inventoryProvider = context.read<InventoryProvider>();
    final products = inventoryProvider.products;

    setState(() {
      _items.addAll(items);
      for (var item in _items) {
        _quantityControllers
            .add(TextEditingController(text: item.quantity.toString()));
        _priceControllers
            .add(TextEditingController(text: item.unitPrice.toString()));
        final product = products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
              id: 0,
              name: '',
              categoryId: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now()),
        );
        _productNameControllers.add(TextEditingController(text: product.name));
      }
      if (widget.purchase != null) {
        _additionalCostController.text =
            widget.purchase!.additionalCost.toString();
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _supplierNameController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _additionalCostController.dispose();
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    for (var controller in _productNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await pickLocalizedDateTime(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            dFormatter.formatLocalizedDateTime(context, picked.toString());
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
    final productUnits = inventoryProvider.getProductUnits(product.id!);

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
        purchaseId: 0,
        productId: product.id!,
        quantity: 0,
        unitId: productUnits.first.id!,
        unitPrice: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _quantityControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
      _productNameControllers.add(TextEditingController(text: product.name));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _quantityControllers[index].dispose();
      _quantityControllers.removeAt(index);
      _priceControllers[index].dispose();
      _priceControllers.removeAt(index);
      _productNameControllers[index].dispose();
      _productNameControllers.removeAt(index);
    });
  }

  void _updateItem(int index, Product product, Unit unit) {
    if (!mounted) return;

    setState(() {
      _items[index] = PurchaseItem(
        id: _items[index].id,
        purchaseId: widget.purchase?.id ?? 0,
        productId: product.id!,
        quantity: double.tryParse(_quantityControllers[index].text) ?? 0,
        unitId: unit.id!,
        unitPrice: double.tryParse(_priceControllers[index].text) ?? 0,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
      // Update the product name controller
      _productNameControllers[index].text = product.name;
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
    }

    final provider = context.read<PurchaseProvider>();

    // Update items before saving
    for (var i = 0; i < _items.length; i++) {
      double quantity = double.tryParse(_quantityControllers[i].text) ?? 0;

      _items[i] = PurchaseItem(
        id: _items[i].id,
        purchaseId: _items[i].purchaseId,
        productId: _items[i].productId,
        quantity: quantity, // <-- stored in base unit
        unitId: _items[i].unitId,
        unitPrice: double.tryParse(_priceControllers[i].text) ?? 0,
        createdAt: _items[i].createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final purchase = Purchase(
      id: widget.purchase?.id,
      supplierId: _selectedSupplier?['id'] ?? 0,
      invoiceNumber: _invoiceNumberController.text,
      date: _selectedDate,
      currency: _selectedCurrency,
      notes: _notesController.text,
      totalAmount:
          _items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice)),
      paidAmount: widget.purchase?.paidAmount ?? 0,
      additionalCost: double.tryParse(_additionalCostController.text) ?? 0,
      dueDate:
          widget.purchase?.dueDate ?? _selectedDate.add(Duration(days: 30)),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.purchase == null
                            ? loc.addPurchase
                            : loc.editPurchase,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoadingSuppliers
                        ? const Center(child: CircularProgressIndicator())
                        : Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _invoiceNumberController,
                                  decoration: InputDecoration(
                                    labelText: loc.invoice,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return loc.requiredField;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _additionalCostController,
                                  decoration: InputDecoration(
                                    labelText: loc.additionalCost,
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                                const SizedBox(height: 16),
                                Autocomplete<Map<String, dynamic>>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _suppliers;
                                    }
                                    return _suppliers.where((supplier) {
                                      return supplier['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(textEditingValue.text
                                              .toLowerCase());
                                    });
                                  },
                                  displayStringForOption: (option) =>
                                      option['name'],
                                  fieldViewBuilder: (context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted) {
                                    // Set the initial text for edit mode
                                    if (widget.purchase != null &&
                                        textEditingController.text.isEmpty) {
                                      textEditingController.text =
                                          _supplierNameController.text;
                                    }
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: loc.supplier,
                                        suffixIcon: _isLoadingSuppliers
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
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
                                      _supplierNameController.text =
                                          supplier['name'];
                                    });
                                  },
                                  optionsViewBuilder:
                                      (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxHeight: 200),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              final option =
                                                  options.elementAt(index);
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
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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

                                  final allUnits = inventoryProvider.units;
                                  final unit = allUnits.firstWhere(
                                    (u) => u.id == item.unitId,
                                    orElse: () => allUnits.first,
                                  );

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                icon: const Icon(Icons.delete),
                                                onPressed: () =>
                                                    _removeItem(index),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Autocomplete<Product>(
                                            optionsBuilder: (TextEditingValue
                                                textEditingValue) {
                                              if (textEditingValue
                                                  .text.isEmpty) {
                                                return products;
                                              }
                                              return products.where((product) {
                                                return product.name
                                                    .toLowerCase()
                                                    .contains(
                                                      textEditingValue.text
                                                          .toLowerCase(),
                                                    );
                                              });
                                            },
                                            displayStringForOption:
                                                (Product product) =>
                                                    product.name,
                                            fieldViewBuilder: (context,
                                                textEditingController,
                                                focusNode,
                                                onFieldSubmitted) {
                                              // Set the initial text for edit mode
                                              if (widget.purchase != null &&
                                                  textEditingController
                                                      .text.isEmpty) {
                                                textEditingController.text =
                                                    _productNameControllers[
                                                            index]
                                                        .text;
                                              }
                                              return TextFormField(
                                                controller:
                                                    textEditingController,
                                                focusNode: focusNode,
                                                decoration: InputDecoration(
                                                  labelText: loc.product,
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return loc.requiredField;
                                                  }
                                                  return null;
                                                },
                                              );
                                            },
                                            onSelected:
                                                (Product selectedProduct) {
                                              final selectedProductUnits =
                                                  inventoryProvider
                                                      .getProductUnits(
                                                          selectedProduct.id!);
                                              final selectedUnit =
                                                  selectedProductUnits.first;
                                              _updateItem(
                                                  index,
                                                  selectedProduct,
                                                  selectedUnit);
                                            },
                                            optionsViewBuilder:
                                                (context, onSelected, options) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  elevation: 4,
                                                  child: ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxHeight: 200),
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      shrinkWrap: true,
                                                      itemCount: options.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        final option = options
                                                            .elementAt(index);
                                                        return ListTile(
                                                          title:
                                                              Text(option.name),
                                                          onTap: () =>
                                                              onSelected(
                                                                  option),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _quantityControllers[
                                                          index],
                                                  decoration: InputDecoration(
                                                    labelText: loc.quantity,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    _updateItem(
                                                        index, product, unit);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    int>(
                                                  value: unit.id,
                                                  decoration: InputDecoration(
                                                    labelText: loc.unit,
                                                  ),
                                                  items: allUnits.map((u) {
                                                    return DropdownMenuItem(
                                                      value: u.id,
                                                      child: Text(
                                                          inventoryProvider
                                                              .getUnitName(
                                                                  u.id)),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      final selectedUnit =
                                                          allUnits.firstWhere(
                                                              (u) =>
                                                                  u.id ==
                                                                  value);
                                                      _updateItem(
                                                          index,
                                                          product,
                                                          selectedUnit);
                                                    }
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
                                                  controller:
                                                      _priceControllers[index],
                                                  decoration: InputDecoration(
                                                      labelText: loc.unitPrice,
                                                      suffixText:
                                                          _selectedCurrency),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    _updateItem(
                                                        index, product, unit);
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
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(loc.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoadingSuppliers ? null : _savePurchase,
                        child: Text(loc.save),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
