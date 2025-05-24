import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/warehouse.dart';

class AddWarehouseDialog extends StatefulWidget {
  const AddWarehouseDialog({Key? key}) : super(key: key);

  @override
  _AddWarehouseDialogState createState() => _AddWarehouseDialogState();
}

class _AddWarehouseDialogState extends State<AddWarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.addNewWarehouse),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.warehouseName,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterWarehouseName;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: loc.address,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterAddress;
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveWarehouse,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.add),
        ),
      ],
    );
  }

  Future<void> _saveWarehouse() async {
    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<InventoryProvider>();
      final warehouse = Warehouse(
        name: _nameController.text,
        address: _addressController.text,
        description: _descriptionController.text,
      );
      await provider.addWarehouse(warehouse);
      await provider.refreshData();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving warehouse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorCreatingWarehouse(e.toString()))),
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
