import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/product.dart';

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
        _isEditing = true;
        _nameController.text = widget.product!.name;
        _descriptionController.text = widget.product!.description ?? '';
        _selectedCategoryId = widget.product!.categoryId;
        _selectedUnitId = widget.product!.unitId;
        _minimumStockController.text = widget.product!.minimumStock.toString();
        _barcodeController.text = widget.product!.barcode ?? '';
        _hasExpiryDate = widget.product!.hasExpiryDate;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
      ),
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
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
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
                          return 'Please select a category';
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
                      decoration: const InputDecoration(
                        labelText: 'Unit',
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
                          return 'Please select a unit';
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
                  decoration: const InputDecoration(
                    labelText: 'Minimum Stock',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter minimum stock';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (Optional)',
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Has Expiry Date'),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final product = Product(
                    id: _isEditing ? widget.product!.id : null,
                    name: _nameController.text,
                    description: _descriptionController.text,
                    categoryId: _selectedCategoryId!,
                    unitId: _selectedUnitId!,
                    minimumStock: double.parse(_minimumStockController.text),
                    reorderPoint: _isEditing ? widget.product!.reorderPoint : 0,
                    maximumStock: _isEditing ? widget.product!.maximumStock : double.infinity,
                    hasExpiryDate: _hasExpiryDate,
                    barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
                    isActive: true,
                  );
                  if (_isEditing) {
                    context.read<InventoryProvider>().updateProduct(product);
                  } else {
                    context.read<InventoryProvider>().addProduct(product);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text(_isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
} 