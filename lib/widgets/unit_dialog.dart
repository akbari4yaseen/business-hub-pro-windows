import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/inventory_provider.dart';
import '../models/unit.dart';

class UnitDialog extends StatefulWidget {
  final Unit? unit;

  const UnitDialog({super.key, this.unit});

  @override
  State<UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _symbolController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _symbolController = TextEditingController(text: widget.unit?.symbol ?? '');
    _descriptionController =
        TextEditingController(text: widget.unit?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? loc.add_unit : loc.edit_unit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: loc.unit_name),
          ),
          TextField(
            controller: _symbolController,
            decoration: InputDecoration(labelText: loc.unit_symbol),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: loc.unit_description),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final unit = Unit(
              id: widget.unit?.id,
              name: name,
              symbol: _symbolController.text.trim().isNotEmpty
                  ? _symbolController.text.trim()
                  : null,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
            );

            final provider = context.read<InventoryProvider>();
            isEditing ? provider.updateUnit(unit) : provider.addUnit(unit);
            Navigator.of(context).pop();
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
