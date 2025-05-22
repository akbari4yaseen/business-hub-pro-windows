// record_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/invoice.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice, double) onPaymentRecorded;

  const RecordPaymentDialog({
    Key? key,
    required this.invoice,
    required this.onPaymentRecorded,
  }) : super(key: key);

  @override
  _RecordPaymentDialogState createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  static final _currencyFormat = NumberFormat('#,###.##');

  @override
  void initState() {
    super.initState();
    _amountController.text = _currencyFormat.format(widget.invoice.balance);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.recordPayment),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.invoiceLabel}: ${widget.invoice.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${loc.outstandingBalance}: ${_currencyFormat.format(widget.invoice.balance)} ${widget.invoice.currency}',
              style: TextStyle(
                color: widget.invoice.isOverdue ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: loc.paymentAmount,
                suffixText: widget.invoice.currency,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterPaymentAmount;
                }

                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null) {
                  return loc.enterValidAmount;
                }

                if (amount <= 0) {
                  return loc.amountGreaterThanZero;
                }

                if (amount > widget.invoice.balance) {
                  return loc.amountExceedsBalance;
                }

                return null;
              },
            ),
          ],
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
              final amount = double.parse(
                _amountController.text.replaceAll(',', ''),
              );
              widget.onPaymentRecorded(widget.invoice, amount);
              Navigator.of(context).pop();
            }
          },
          child: Text(loc.recordPayment),
        ),
      ],
    );
  }
}
