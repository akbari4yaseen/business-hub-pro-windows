import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../models/stock_movement.dart';
import '../../utils/inventory.dart';
import '../../models/product.dart';
import '../../utils/date_formatters.dart';

class MovementDetailsSheet extends StatelessWidget {
  final StockMovement movement;
  final Product product;
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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.movementDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(loc.product, product.name),
                  _buildDetailRow(loc.type, movement.type.localized(context)),
                  _buildDetailRow(
                    loc.quantity,
                    '${numberFormatter.format(movement.quantity)} $unitName',
                  ),
                  _buildDetailRow(loc.source, sourceLocation),
                  _buildDetailRow(loc.description, destinationLocation),
                  if (movement.reference != null)
                    _buildDetailRow(loc.reference, movement.reference!),
                  if (movement.notes != null)
                    _buildDetailRow(loc.notes, movement.notes!),
                  if (movement.expiryDate != null)
                    _buildDetailRow(
                      loc.expiryDate,
                      formatLocalizedDate(
                        context,
                        movement.expiryDate.toString(),
                      ),
                    ),
                  _buildDetailRow(
                    loc.date,
                    formatLocalizedDateTime(
                      context,
                      movement.date.toString(),
                    ),
                  ),
                  _buildDetailRow(
                    loc.createdAt,
                    formatLocalizedDateTime(
                      context,
                      movement.createdAt.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
