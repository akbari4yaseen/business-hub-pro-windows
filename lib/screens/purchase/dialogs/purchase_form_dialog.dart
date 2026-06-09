import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase.dart';
import '../../../models/product.dart';
import '../../../models/unit.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../constants/currencies.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;
import '../../../themes/app_theme.dart';

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
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##');

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

  InputDecoration _fieldDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      suffixIcon: suffixIcon,
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

  double _lineTotal(int index) {
    final qty = double.tryParse(_quantityControllers[index].text) ?? 0;
    final price = double.tryParse(_priceControllers[index].text) ?? 0;
    return qty * price;
  }

  double get _itemsSubtotal =>
      List.generate(_items.length, _lineTotal).fold(0.0, (a, b) => a + b);

  double get _additionalCost =>
      double.tryParse(_additionalCostController.text) ?? 0;

  double get _grandTotal => _itemsSubtotal + _additionalCost;

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
    final allUnits = inventoryProvider.units;

    if (allUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.no_units),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final defaultUnit = product.baseUnitId != null
        ? allUnits.firstWhere(
            (u) => u.id == product.baseUnitId,
            orElse: () => allUnits.first,
          )
        : allUnits.first;

    setState(() {
      _items.add(PurchaseItem(
        purchaseId: 0,
        productId: product.id!,
        quantity: 0,
        unitId: defaultUnit.id!,
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
      _productNameControllers[index].text = product.name;
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

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

    for (var i = 0; i < _items.length; i++) {
      double quantity = double.tryParse(_quantityControllers[i].text) ?? 0;

      _items[i] = PurchaseItem(
        id: _items[i].id,
        purchaseId: _items[i].purchaseId,
        productId: _items[i].productId,
        quantity: quantity,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final products = inventoryProvider.products;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1100,
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Column(
              children: [
                _buildDialogHeader(context, loc, theme, colorScheme),
                const Divider(height: 1),
                Expanded(
                  child: _isLoadingSuppliers
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMetaSection(
                                    context, loc, theme, colorScheme),
                                const SizedBox(height: 24),
                                _buildItemsSection(
                                  context,
                                  loc,
                                  theme,
                                  colorScheme,
                                  inventoryProvider,
                                  products,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const Divider(height: 1),
                _buildFooter(context, loc, theme, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      color: colorScheme.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.purchase == null ? loc.addPurchase : loc.editPurchase,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: loc.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.invoiceDetails,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _invoiceNumberController,
                  decoration: _fieldDecoration(
                    label: loc.invoice,
                    prefixIcon: Icons.receipt_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.requiredField;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: _fieldDecoration(
                    label: loc.date,
                    prefixIcon: Icons.calendar_today,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _suppliers;
                    }
                    return _suppliers.where((supplier) {
                      return supplier['name']
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  displayStringForOption: (option) => option['name'],
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    if (widget.purchase != null &&
                        textEditingController.text.isEmpty) {
                      textEditingController.text = _supplierNameController.text;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: _fieldDecoration(
                        label: loc.supplier,
                        prefixIcon: Icons.local_shipping_outlined,
                        suffixIcon: _isLoadingSuppliers
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
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
                        elevation: 6,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: _fieldDecoration(
                    label: loc.currency,
                    prefixIcon: Icons.payments_outlined,
                  ),
                  items: currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _additionalCostController,
                  decoration: _fieldDecoration(
                    label: loc.additionalCost,
                    prefixIcon: Icons.add_circle_outline,
                    suffixText: _selectedCurrency,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _notesController,
                  decoration: _fieldDecoration(
                    label: loc.notes,
                    prefixIcon: Icons.notes_outlined,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    InventoryProvider inventoryProvider,
    List<Product> products,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.items,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_items.isNotEmpty)
                      Text(
                        '${_items.length} ${_items.length == 1 ? loc.item : loc.items}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.addItem),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            _buildEmptyItemsState(loc, theme, colorScheme)
          else ...[
            const SizedBox(height: 12),
            ...List.generate(_items.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _items.length - 1 ? 10 : 0,
                ),
                child: _buildPurchaseItemRow(
                  context,
                  loc,
                  theme,
                  colorScheme,
                  inventoryProvider,
                  products,
                  index,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState(
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            loc.noItemsAdded,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: Text(loc.addItem),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItemRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    InventoryProvider inventoryProvider,
    List<Product> products,
    int index,
  ) {
    final item = _items[index];
    final product = products.firstWhere(
      (p) => p.id == item.productId,
      orElse: () => products.first,
    );
    final allUnits = inventoryProvider.units;
    if (allUnits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${loc.item} ${index + 1}: ${loc.no_units}',
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
      );
    }
    final unit = allUnits.firstWhere(
      (u) => u.id == item.unitId,
      orElse: () => allUnits.first,
    );
    final lineTotal = _lineTotal(index);

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
          Container(
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
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${loc.item} ${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lineTotal > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${loc.subtotal}: ${_amountFormat.format(lineTotal)} $_selectedCurrency',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => _removeItem(index),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Autocomplete<Product>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return products;
                    }
                    return products.where((product) {
                      return product.name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                    });
                  },
                  displayStringForOption: (Product product) => product.name,
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    if (widget.purchase != null &&
                        textEditingController.text.isEmpty) {
                      textEditingController.text =
                          _productNameControllers[index].text;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: _fieldDecoration(
                        label: loc.product,
                        prefixIcon: Icons.search,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.requiredField;
                        }
                        return null;
                      },
                    );
                  },
                  onSelected: (Product selectedProduct) {
                    final allUnits = inventoryProvider.units;
                    final selectedUnit = selectedProduct.baseUnitId != null
                        ? allUnits.firstWhere(
                            (u) => u.id == selectedProduct.baseUnitId,
                            orElse: () => allUnits.first,
                          )
                        : allUnits.first;
                    _updateItem(index, selectedProduct, selectedUnit);
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                            itemBuilder: (context, optionIndex) {
                              final option = options.elementAt(optionIndex);
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                title: Text(option.name),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityControllers[index],
                        decoration: _fieldDecoration(
                          label: loc.quantity,
                          prefixIcon: Icons.numbers,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}')),
                        ],
                        onChanged: (_) => _updateItem(index, product, unit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: allUnits.isEmpty
                          ? InputDecorator(
                              decoration: _fieldDecoration(
                                label: loc.unit,
                                prefixIcon: Icons.straighten_outlined,
                              ),
                              child: Text(
                                '—',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              decoration: _fieldDecoration(
                                label: loc.unit,
                                prefixIcon: Icons.straighten_outlined,
                              ),
                              value: unit.id,
                              items: allUnits.map((u) {
                                return DropdownMenuItem(
                                  value: u.id,
                                  child: Text(
                                    inventoryProvider.getUnitName(u.id),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  final selectedUnit = allUnits.firstWhere(
                                    (u) => u.id == value,
                                  );
                                  _updateItem(index, product, selectedUnit);
                                }
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceControllers[index],
                        decoration: _fieldDecoration(
                          label: loc.unitPrice,
                          prefixIcon: Icons.attach_money,
                          suffixText: _selectedCurrency,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}')),
                        ],
                        onChanged: (_) => _updateItem(index, product, unit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: _fieldDecoration(label: loc.subtotal),
                        child: Text(
                          _amountFormat.format(lineTotal),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          if (_items.isNotEmpty) ...[
            _buildTotalChip(
              label: loc.subtotal,
              value: _amountFormat.format(_itemsSubtotal),
              currency: _selectedCurrency,
              theme: theme,
              colorScheme: colorScheme,
              emphasized: false,
            ),
            const SizedBox(width: 12),
            _buildTotalChip(
              label: loc.additionalCost,
              value: _amountFormat.format(_additionalCost),
              currency: _selectedCurrency,
              theme: theme,
              colorScheme: colorScheme,
              emphasized: false,
            ),
            const SizedBox(width: 12),
            _buildTotalChip(
              label: loc.total,
              value: _amountFormat.format(_grandTotal),
              currency: _selectedCurrency,
              theme: theme,
              colorScheme: colorScheme,
              emphasized: true,
            ),
            const Spacer(),
          ] else
            const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoadingSuppliers ? null : _savePurchase,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(loc.save),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalChip({
    required String label,
    required String value,
    required String currency,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool emphasized,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasized
              ? AppTheme.primaryColor.withValues(alpha: 0.25)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value $currency',
            style: (emphasized
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
              color: emphasized ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
