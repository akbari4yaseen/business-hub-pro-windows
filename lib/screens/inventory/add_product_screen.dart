import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/product.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  bool _hasExpiryDate = false;
  int? _selectedCategoryId;
  int? _selectedUnitId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      provider.initialize();
      if (widget.product != null) {
        setState(() {
          _isEditing = true;
          _nameController.text = widget.product!.name;
          _descriptionController.text = widget.product!.description;
          _selectedCategoryId = widget.product!.categoryId;
          _selectedUnitId = widget.product!.unitId;
          _minimumStockController.text =
              widget.product!.minimumStock.toString();
          _barcodeController.text = widget.product!.barcode ?? '';
          _hasExpiryDate = widget.product!.hasExpiryDate;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId!,
        unitId: _selectedUnitId!,
        minimumStock: double.parse(_minimumStockController.text),
        reorderPoint: _isEditing ? widget.product!.reorderPoint : 0,
        maximumStock:
            _isEditing ? widget.product!.maximumStock : double.infinity,
        hasExpiryDate: _hasExpiryDate,
        barcode:
            _barcodeController.text.isEmpty ? null : _barcodeController.text,
        isActive: true,
      );

      final inventoryProvider = context.read<InventoryProvider>();

      if (_isEditing) {
        inventoryProvider.updateProduct(product);
      } else {
        inventoryProvider.addProduct(product);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? loc.editProduct : loc.addNewProduct),
        actions: [
          IconButton(onPressed: _handleSubmit, icon: const Icon(Icons.save)),
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
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.productName,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.pleaseEnterProductName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.description,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.category,
                      ),
                      value: _selectedCategoryId,
                      items: provider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return loc.pleaseSelectCategory;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.unit,
                      ),
                      value: _selectedUnitId,
                      items: provider.units.map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return loc.pleaseSelectUnit;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minimumStockController,
                  decoration: InputDecoration(
                    labelText: loc.minimumStock,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.pleaseEnterMinimumStock;
                    }
                    if (double.tryParse(value) == null) {
                      return loc.pleaseEnterValidNumber;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: loc.barcodeOptional,
                  ),
                ),
                CheckboxListTile(
                  title: Text(loc.hasExpiryDate),
                  value: _hasExpiryDate,
                  onChanged: (value) {
                    setState(() {
                      _hasExpiryDate = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
