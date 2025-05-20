import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/journal/journal_form_widgets.dart';
import '../../providers/settings_provider.dart';
import '../../constants/currencies.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/account_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({
    Key? key,
    this.invoice,
  }) : super(key: key);

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<InvoiceItemFormData> _items = [];
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  late String _currency;
  int? _selectedAccountId;
  static final _currencyFormat = NumberFormat('#,####.##');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure accounts are loaded
    Future.microtask(() {
      // If editing an existing invoice, populate the form
      if (widget.invoice != null) {
        _populateForm(widget.invoice!);
      } else {
        // Add initial item by default for better UX
        _addItem();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _currency = settingsProvider.defaultCurrency;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<SettingsProvider>();
    _currency = settings.defaultCurrency;
  }

  void _populateForm(Invoice invoice) {
    setState(() {
      _selectedAccountId = invoice.accountId;
      _date = invoice.date;
      _dueDate = invoice.dueDate;
      _currency = invoice.currency;
      _notesController.text = invoice.notes ?? '';

      // Clear existing items and add invoice items
      for (final item in _items) {
        item.dispose();
      }
      _items.clear();

      for (final item in invoice.items) {
        final formData = InvoiceItemFormData();
        formData.selectedProductId = item.productId;
        formData.quantityController.text = item.quantity.toString();
        formData.unitPriceController.text =
            _currencyFormat.format(item.unitPrice);
        formData.descriptionController.text = item.description ?? '';
        _items.add(formData);
      }
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
        title: Text(widget.invoice != null ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          if (widget.invoice != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Delete Invoice',
            ),
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
              : IconButton(
                  onPressed: _items.isEmpty ? null : _submitForm,
                  icon: Icon(Icons.save)),
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
                            subtitle: Text(
                                formatLocalizedDate(context, _date.toString())),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Due Date'),
                            subtitle: _dueDate != null
                                ? Text(formatLocalizedDate(
                                    context, _dueDate.toString()))
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
                      ),
                      items: currencies
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
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
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Total
            Card(
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

                return AccountField(
                  label: 'Customer Account',
                  accounts: customers,
                  initialValue: _selectedAccountId != null
                      ? TextEditingValue(
                          text: customers.firstWhere(
                              (c) => c['id'] == _selectedAccountId)['name'],
                        )
                      : null,
                  onSelected: (id) {
                    setState(() {
                      _selectedAccountId = id;
                    });
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      final invoiceNumber = widget.invoice?.invoiceNumber ??
          await invoiceProvider.generateInvoiceNumber();

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
        id: widget.invoice?.id,
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

      if (widget.invoice != null) {
        await invoiceProvider.updateInvoice(invoice);
      } else {
        await invoiceProvider.createInvoice(invoice);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error ${widget.invoice != null ? "updating" : "creating"} invoice: ${e.toString()}')),
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

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
            'Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context
            .read<InvoiceProvider>()
            .deleteInvoice(widget.invoice!.id!);
        if (context.mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting invoice: $e')),
          );
        }
      }
    }
  }
}

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
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: formData.selectedProductId != null
                          ? TextEditingValue(
                              text: products
                                  .firstWhere((p) => p.id == formData.selectedProductId)
                                  .name,
                            )
                          : null,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return products.map((product) {
                            final stock = provider.getCurrentStockForProduct(product.id!);
                            final totalStock = stock.fold<double>(
                                0, (sum, item) => sum + (item['quantity'] as double));
                            return {
                              'id': product.id,
                              'name': product.name,
                              'stock': totalStock,
                            };
                          }).toList();
                        }
                        return products.where((product) {
                          return product.name.toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        }).map((product) {
                          final stock = provider.getCurrentStockForProduct(product.id!);
                          final totalStock = stock.fold<double>(
                              0, (sum, item) => sum + (item['quantity'] as double));
                          return {
                            'id': product.id,
                            'name': product.name,
                            'stock': totalStock,
                          };
                        }).toList();
                      },
                      displayStringForOption: (option) => option['name'],
                      onSelected: (option) {
                        formData.selectedProductId = option['id'];
                        final product = products.firstWhere((p) => p.id == option['id']);
                        
                        // Set description if the product has one
                        if (product.description.isNotEmpty) {
                          formData.descriptionController.text = product.description;
                        }

                        // Check if we have stock
                        final stock = provider.getCurrentStockForProduct(product.id!);
                        final totalStock = stock.fold<double>(
                            0, (sum, item) => sum + (item['quantity'] as double));

                        if (totalStock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Warning: No stock available for ${product.name}'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a product';
                            }
                            return null;
                          },
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
                                      'Stock: ${option['stock'].toStringAsFixed(2)}',
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
