import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/invoice.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../widgets/journal/journal_form_widgets.dart';
import '../../providers/settings_provider.dart';
import '../../constants/currencies.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/invoice/invoice_item_form.dart';

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
  final _dateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final List<InvoiceItemFormData> _items = [];
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  late String _currency;
  int? _selectedAccountId;
  static final _currencyFormat = NumberFormat('#,###.##');
  bool _isSubmitting = false;
  final ValueNotifier<double> _totalNotifier = ValueNotifier<double>(0);

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
      _dateController.text =
          dFormatter.formatLocalizedDateTime(context, _date.toString());
      if (_dueDate != null) {
        _dueDateController.text =
            dFormatter.formatLocalizedDateTime(context, _dueDate.toString());
      }
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
    _dateController.dispose();
    _dueDateController.dispose();
    _totalNotifier.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItemFormData());
      _updateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
      _updateTotal();
    });
  }

  void _updateTotal() {
    _totalNotifier.value = _items.fold(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final result = await pickLocalizedDate(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? _date) : _date,
    );
    if (result != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = result;
          _dueDateController.text =
              dFormatter.formatLocalizedDate(context, result.toString());
        } else {
          _date = result;
          _dateController.text =
              dFormatter.formatLocalizedDate(context, result.toString());
          if (_dueDate != null && _dueDate!.isBefore(_date)) {
            _dueDate = null;
            _dueDateController.clear();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.invoice != null ? loc.editInvoice : loc.createInvoice),
        actions: [
          if (widget.invoice != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: loc.deleteInvoice,
            ),
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _items.isEmpty ? null : _submitForm,
                  icon: const Icon(Icons.save),
                ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;

          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _buildAccountSelection(context)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildInvoiceMeta(loc)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildAccountSelection(context),
                                  const SizedBox(height: 16),
                                  _buildInvoiceMeta(loc),
                                ],
                              ),
                        const SizedBox(height: 24),
                        _buildItemsCard(loc),
                        const SizedBox(height: 24),
                        _buildNotesCard(loc),
                        const SizedBox(height: 24),
                        _buildTotalCard(loc),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceMeta(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.invoiceDetails,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: loc.invoiceDate,
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dueDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: loc.dueDate,
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: loc.currency),
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.items,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: Text(loc.addItem),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(loc.noItemsAdded)))
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return InvoiceItemForm(
                  key: ObjectKey(item),
                  formData: item,
                  onRemove: () => _removeItem(index),
                  onUpdate: _updateTotal,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.additionalInformation,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: loc.notes),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.total,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ValueListenableBuilder<double>(
              valueListenable: _totalNotifier,
              builder: (context, total, child) {
                return Text(
                  '${_currencyFormat.format(total)} $_currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelection(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.customer,
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
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(loc.noCustomersFound),
                    ),
                  );
                }

                return AccountField(
                  label: loc.customerAccount,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      final loc = AppLocalizations.of(context)!;
      final invoiceNumber = widget.invoice?.invoiceNumber ??
          await invoiceProvider.generateInvoiceNumber();

      for (final item in _items) {
        if (item.selectedProductId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseSelectAccount)),
          );
          return;
        }
        if (item.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.quantityMustBeGreaterThanZero)),
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
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteInvoice),
        content: Text(loc.deleteInvoiceConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.delete),
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
            SnackBar(content: Text(loc.invoiceDeleted)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.errorDeletingInvoice}: $e')),
          );
        }
      }
    }
  }
}
