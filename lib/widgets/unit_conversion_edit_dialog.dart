import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/unit.dart';
import '../providers/inventory_provider.dart';

class UnitConversionEditDialog extends StatefulWidget {
  final UnitConversion? conversion;
  const UnitConversionEditDialog({Key? key, this.conversion}) : super(key: key);

  @override
  State<UnitConversionEditDialog> createState() => _UnitConversionEditDialogState();
}

class _UnitConversionEditDialogState extends State<UnitConversionEditDialog> {
  int? _fromUnitId;
  int? _toUnitId;
  final _factorController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.conversion != null) {
      _fromUnitId = widget.conversion!.fromUnitId;
      _toUnitId = widget.conversion!.toUnitId;
      _factorController.text = widget.conversion!.factor.toString();
    }
  }

  @override
  void dispose() {
    _factorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<InventoryProvider>();
    final units = provider.units;

    return AlertDialog(
      title: Text(widget.conversion == null ? (loc.add_unit_conversion) : (loc.edit_unit_conversion)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _fromUnitId,
            items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
            onChanged: (v) => setState(() => _fromUnitId = v),
            decoration: InputDecoration(labelText: loc.from_unit),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _toUnitId,
            items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
            onChanged: (v) => setState(() => _toUnitId = v),
            decoration: InputDecoration(labelText: loc.to_unit),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _factorController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: loc.conversion_rate),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : () async {
            if (_fromUnitId == null || _toUnitId == null || _factorController.text.isEmpty) return;
            setState(() => _isSaving = true);
            final factor = double.tryParse(_factorController.text) ?? 1.0;
            final conversion = UnitConversion(
              id: widget.conversion?.id,
              fromUnitId: _fromUnitId!,
              toUnitId: _toUnitId!,
              factor: factor,
            );
            if (widget.conversion == null) {
              await provider.addUnitConversion(conversion);
            } else {
              await provider.updateUnitConversion(conversion);
            }
            if (mounted) Navigator.of(context).pop();
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
} 