import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return AlertDialog(
      title: const Text('Move Stock'),
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
                    decoration: const InputDecoration(
                      labelText: 'Destination Warehouse',
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
                        return 'Please select a warehouse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity';
                      }
                      final num? quantity = num.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a valid quantity';
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implement move stock logic between warehouses
              Navigator.of(context).pop();
            }
          },
          child: const Text('Move'),
        ),
      ],
    );
  }
}
