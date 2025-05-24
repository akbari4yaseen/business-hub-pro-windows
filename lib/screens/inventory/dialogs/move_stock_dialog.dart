import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/stock_movement.dart';

class MoveStockDialog extends StatefulWidget {
  final Map<String, dynamic> stockItem;

  const MoveStockDialog({
    Key? key,
    required this.stockItem,
  }) : super(key: key);

  @override
  State<MoveStockDialog> createState() => _MoveStockDialogState();
}

class _MoveStockDialogState extends State<MoveStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.stockItem['warehouse_name'];
    _quantityController.text = widget.stockItem['quantity'].toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.moveStock),
      content: Form(
        key: _formKey,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            final warehouses = provider.warehouses.map((w) => w.name).toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedWarehouse,
                    decoration: InputDecoration(
                      labelText: loc.destinationWarehouse,
                    ),
                    items: warehouses
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWarehouse = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return loc.pleaseSelectWarehouse;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: loc.quantity,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.pleaseEnterQuantity;
                      }
                      final num? quantity = num.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return loc.enterValidQuantity;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implement move stock logic between warehouses
              Navigator.of(context).pop();
            }
          },
          child: Text(loc.move),
        ),
      ],
    );
  }
}
