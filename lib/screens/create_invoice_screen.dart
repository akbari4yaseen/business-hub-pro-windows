import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

import '../providers/invoice_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/account_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({Key? key}) : super(key: key);

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<InvoiceItemFormData> _items = [];
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  String _currency = 'USD'; // Default currency
  int? _selectedAccountId;
  static final _currencyFormat = NumberFormat('#,##0.00');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure accounts are loaded
    Future.microtask(() {
      context.read<AccountProvider>().initialize();
      context.read<InventoryProvider>().initialize();
      // Add initial item by default for better UX
      _addItem();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItemFormData());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _date : DateTime.now(),
      firstDate: isDueDate ? _date : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _date = picked;
          if (_dueDate != null && _dueDate!.isBefore(_date)) {
            _dueDate = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice'),
        actions: [
          _isSubmitting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _items.isEmpty ? null : _submitForm,
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Customer Account Selection
            _buildAccountSelection(),
            const SizedBox(height: 16),

            // Dates and Currency
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Invoice Date'),
                            subtitle:
                                Text(DateFormat('MMM d, y').format(_date)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Due Date'),
                            subtitle: _dueDate != null
                                ? Text(DateFormat('MMM d, y').format(_dueDate!))
                                : const Text('Not set'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Currency Selection
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currency = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invoice Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                              'No items added yet. Press "Add Item" to begin.'),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return InvoiceItemForm(
                          key: ObjectKey(item),
                          formData: item,
                          onRemove: () => _removeItem(index),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Total
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(_calculateTotal())} $_currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                final customers = accountProvider.customers;

                if (customers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                          'No customers found. Please add a customer account first.'),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Customer Account',
                    border: OutlineInputBorder(),
                  ),
                  items: customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer['id'] as int,
                      child: Text(customer['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _items.fold(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      final invoiceNumber = await invoiceProvider.generateInvoiceNumber();

      for (final item in _items) {
        if (item.selectedProductId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a product for all items')),
          );
          return;
        }
        if (item.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Quantity must be greater than 0 for all items')),
          );
          return;
        }
      }

      final invoice = Invoice(
        accountId: _selectedAccountId!,
        invoiceNumber: invoiceNumber,
        date: _date,
        currency: _currency,
        notes: _notesController.text,
        dueDate: _dueDate,
        items: _items
            .map((item) => InvoiceItem(
                  productId: item.selectedProductId!,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  description: item.description,
                ))
            .toList(),
      );

      await invoiceProvider.createInvoice(invoice);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: ${e.toString()}')),
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
}

class InvoiceItemFormData {
  final quantityController = TextEditingController(text: '1');
  final unitPriceController = TextEditingController(text: '0.00');
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

class InvoiceItemForm extends StatelessWidget {
  final InvoiceItemFormData formData;
  final VoidCallback onRemove;

  const InvoiceItemForm({
    Key? key,
    required this.formData,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'No products available. Please add products to inventory first.'),
                  );
                }

                return Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: formData.selectedProductId,
                      decoration: const InputDecoration(
                        labelText: 'Product',
                        border: OutlineInputBorder(),
                      ),
                      items: products.map((product) {
                        final stock =
                            provider.getCurrentStockForProduct(product.id!);
                        final totalStock = stock.fold<double>(0,
                            (sum, item) => sum + (item['quantity'] as double));

                        return DropdownMenuItem(
                          value: product.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: totalStock > 0
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Stock: ${totalStock.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: totalStock > 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        formData.selectedProductId = value;
                        if (value != null) {
                          final product =
                              products.firstWhere((p) => p.id == value);
                          // Set description if the product has one
                          if (product.description.isNotEmpty) {
                            formData.descriptionController.text =
                                product.description;
                          }

                          // Check if we have stock
                          final stock =
                              provider.getCurrentStockForProduct(product.id!);
                          final totalStock = stock.fold<double>(
                              0,
                              (sum, item) =>
                                  sum + (item['quantity'] as double));

                          if (totalStock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Warning: No stock available for ${product.name}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a product';
                        return null;
                      },
                    ),
                    if (formData.selectedProductId != null)
                      _buildStockInfo(provider, formData.selectedProductId!),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: formData.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Invalid quantity';
                      }

                      // Check if we have enough stock
                      if (formData.selectedProductId != null) {
                        final provider = Provider.of<InventoryProvider>(context,
                            listen: false);
                        final stock = provider.getCurrentStockForProduct(
                            formData.selectedProductId!);
                        final totalStock = stock.fold<double>(0,
                            (sum, item) => sum + (item['quantity'] as double));

                        if (quantity > totalStock) {
                          return 'Not enough stock (${totalStock.toStringAsFixed(2)})';
                        }
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: formData.unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value.replaceAll(',', ''));
                      if (price == null || price <= 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: formData.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remove',
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

    if (stock.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No stock available',
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
          const Text(
            'Available Stock:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...stock.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['warehouse_name']}'),
                    Text(
                      '${item['quantity']} ${item['unit_name'] ?? ''}',
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
