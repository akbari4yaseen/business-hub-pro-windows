import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  static final _currencyFormat = NumberFormat('#,##0.00');

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
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice: ${widget.invoice.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Outstanding Balance: ${_currencyFormat.format(widget.invoice.balance)} ${widget.invoice.currency}',
              style: TextStyle(
                color: widget.invoice.isOverdue ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                suffixText: widget.invoice.currency,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null) {
                  return 'Please enter a valid amount';
                }
                
                if (amount <= 0) {
                  return 'Amount must be greater than zero';
                }
                
                if (amount > widget.invoice.balance) {
                  return 'Amount cannot exceed outstanding balance';
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
          child: const Text('Cancel'),
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
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
} 