import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../models/stock_movement.dart';
import '../../utils/inventory.dart';
import '../../utils/date_formatters.dart';

class MovementDetailsSheet extends StatelessWidget {
  final StockMovement movement;
  final dynamic product;
  final String sourceLocation;
  final String destinationLocation;
  final String unitName;
  final NumberFormat numberFormatter;

  const MovementDetailsSheet({
    Key? key,
    required this.movement,
    required this.product,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.unitName,
    required this.numberFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: 500,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      loc.movementType, movement.type.localized(context)),
                  _buildDetailRow(loc.quantity,
                      '${numberFormatter.format(movement.quantity)} $unitName'),
                  _buildDetailRow(loc.source, sourceLocation),
                  _buildDetailRow(loc.destination, destinationLocation),
                  if (movement.reference?.isNotEmpty ?? false)
                    _buildDetailRow(loc.reference, movement.reference!),
                  if (movement.notes?.isNotEmpty ?? false)
                    _buildDetailRow(loc.notes, movement.notes!),
                  if (movement.expiryDate != null)
                    _buildDetailRow(
                      loc.expiryDate,
                      formatLocalizedDate(
                          context, movement.expiryDate.toString()),
                    ),
                  _buildDetailRow(
                    loc.date,
                    formatLocalizedDateTime(context, movement.date.toString()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
