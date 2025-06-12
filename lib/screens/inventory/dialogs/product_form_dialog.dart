import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../models/product.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductFormDialog({
    Key? key,
    this.product,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  bool _hasExpiryDate = false;
  int? _selectedCategoryId;
  int? _selectedUnitId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description!;
      _selectedCategoryId = widget.product!.categoryId;
      _selectedUnitId = widget.product!.unitId;
      _minimumStockController.text = widget.product!.minimumStock.toString();
      _barcodeController.text = widget.product!.barcode ?? '';
      _hasExpiryDate = widget.product!.hasExpiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final product = Product(
        id: widget.product?.id ?? 0,
        name: _nameController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
        unitId: _selectedUnitId,
        minimumStock: double.parse(_minimumStockController.text),
        reorderPoint: widget.product?.reorderPoint,
        hasExpiryDate: _hasExpiryDate,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        isActive: true,
      );

      final provider = context.read<InventoryProvider>();
      if (widget.product == null) {
        await provider.addProduct(product);
      } else {
        await provider.updateProduct(product);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isEdit = widget.product != null;

    return Dialog(
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
                          isEdit ? Icons.edit : Icons.add_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? loc.editProduct : loc.addNewProduct,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form fields
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.productName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.pleaseEnterProductName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: loc.description,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Consumer<InventoryProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: loc.category,
                            border: const OutlineInputBorder(),
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
                            border: const OutlineInputBorder(),
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
                        border: const OutlineInputBorder(),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: loc.barcode,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(loc.hasExpiryDate),
                      value: _hasExpiryDate,
                      onChanged: (value) {
                        setState(() {
                          _hasExpiryDate = value;
                        });
                      },
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
                          onPressed: _isSubmitting ? null : _handleSave,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(loc.save),
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
    );
  }
} 