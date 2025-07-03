import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/unit.dart';

class UnitConversionDialog extends StatefulWidget {
  final Unit fromUnit;
  final Unit toUnit;
  final double? initialValue;

  const UnitConversionDialog({
    super.key,
    required this.fromUnit,
    required this.toUnit,
    this.initialValue,
  });

  @override
  State<UnitConversionDialog> createState() => _UnitConversionDialogState();
}

class _UnitConversionDialogState extends State<UnitConversionDialog> {
  late final TextEditingController _fromValueController;
  late final TextEditingController _toValueController;
  double _conversionRate = 1.0;

  @override
  void initState() {
    super.initState();
    _fromValueController = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
    _toValueController = TextEditingController();
    _updateConversion();
  }

  @override
  void dispose() {
    _fromValueController.dispose();
    _toValueController.dispose();
    super.dispose();
  }

  void _updateConversion() {
    if (_fromValueController.text.isEmpty) {
      _toValueController.clear();
      return;
    }

    try {
      final fromValue = double.parse(_fromValueController.text);
      final convertedValue = fromValue * _conversionRate;
      _toValueController.text = convertedValue.toStringAsFixed(2);
    } catch (e) {
      _toValueController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.unit_conversion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${loc.from} ${widget.fromUnit.name}',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _updateConversion(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _toValueController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '${loc.to} ${widget.toUnit.name}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.conversion_rate,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _conversionRate = double.tryParse(value) ?? 1.0;
                _updateConversion();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.close),
        ),
      ],
    );
  }
}
