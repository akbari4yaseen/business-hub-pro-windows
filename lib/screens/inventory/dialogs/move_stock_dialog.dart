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
  String? _selectedZone;
  String? _selectedBin;
  List<String> _zoneOptions = [];
  List<String> _binOptions = [];

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.stockItem['warehouse_name'];
    _selectedZone = widget.stockItem['zone_name'];
    _selectedBin = widget.stockItem['bin_name'];
    _quantityController.text = widget.stockItem['quantity'].toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateZones(InventoryProvider provider) {
    if (_selectedWarehouse != null) {
      final warehouse =
          provider.warehouses.firstWhere((w) => w.name == _selectedWarehouse);
      _zoneOptions =
          provider.getWarehouseZones(warehouse.id!).map((z) => z.name).toList();
      if (!_zoneOptions.contains(_selectedZone)) {
        _selectedZone = null;
      }
      _updateBins(provider);
    } else {
      _zoneOptions = [];
      _selectedZone = null;
      _binOptions = [];
      _selectedBin = null;
    }
  }

  void _updateBins(InventoryProvider provider) {
    if (_selectedZone != null) {
      final zone = provider.zones.firstWhere((z) => z.name == _selectedZone);
      _binOptions = provider.getZoneBins(zone.id!).map((b) => b.name).toList();
      if (!_binOptions.contains(_selectedBin)) {
        _selectedBin = null;
      }
    } else {
      _binOptions = [];
      _selectedBin = null;
    }
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
                  Text(
                    'Product: ${widget.stockItem['product_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Move',
                      hintText: 'Enter quantity',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Please enter a valid quantity';
                      }
                      if (quantity > widget.stockItem['quantity']) {
                        return 'Cannot move more than available quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                        _updateZones(provider);
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
                  DropdownButtonFormField<String>(
                    value: _selectedZone,
                    decoration: const InputDecoration(
                      labelText: 'Destination Zone',
                    ),
                    items: _zoneOptions
                        .map((z) => DropdownMenuItem(
                              value: z,
                              child: Text(z),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedZone = value;
                        _updateBins(provider);
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a zone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBin,
                    decoration: const InputDecoration(
                      labelText: 'Destination Bin',
                    ),
                    items: _binOptions
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBin = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a bin';
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
          onPressed: () => _moveStock(context),
          child: const Text('Move'),
        ),
      ],
    );
  }

  Future<void> _moveStock(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();

      // Get source and destination bins
      final sourceBin = provider.bins.firstWhere(
        (b) => b.name == widget.stockItem['bin_name'],
      );
      final destinationBin = provider.bins.firstWhere(
        (b) => b.name == _selectedBin,
      );

      // Create stock movement
      final movement = StockMovement(
        productId: widget.stockItem['product_id'],
        sourceBinId: sourceBin.id,
        destinationBinId: destinationBin.id,
        quantity: double.parse(_quantityController.text),
        type: MovementType.transfer,
        reference: 'Manual Transfer',
        notes:
            'Stock moved from ${widget.stockItem['bin_name']} to $_selectedBin',
      );

      await provider.recordStockMovement(movement);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
