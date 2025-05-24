import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/inventory_provider.dart';
import '../../../models/warehouse.dart';

class EditWarehouseDialog extends StatefulWidget {
  final Warehouse warehouse;

  const EditWarehouseDialog({
    Key? key,
    required this.warehouse,
  }) : super(key: key);

  @override
  State<EditWarehouseDialog> createState() => _EditWarehouseDialogState();
}

class _EditWarehouseDialogState extends State<EditWarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse.name);
    _addressController = TextEditingController(text: widget.warehouse.address);
    _descriptionController = TextEditingController(text: widget.warehouse.description);
  }

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
      title: Text(loc.editWarehouse),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.name,
                  hintText: loc.enterWarehouseName,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: loc.address,
                  hintText: loc.enterAddress,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterAddress;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.description,
                  hintText: loc.enterWarehouseDescriptionOptional,
                ),
                maxLines: 3,
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updatedWarehouse = Warehouse(
                id: widget.warehouse.id,
                name: _nameController.text,
                address: _addressController.text,
                description: _descriptionController.text,
              );

              await context.read<InventoryProvider>().updateWarehouse(updatedWarehouse);
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
