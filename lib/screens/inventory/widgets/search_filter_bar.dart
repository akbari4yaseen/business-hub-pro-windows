import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchFilterBar extends StatelessWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onWarehouseChanged;
  final Function(String?) onCategoryChanged;
  final List<String> warehouses;
  final List<String> categories;

  const SearchFilterBar({
    Key? key,
    required this.onSearchChanged,
    required this.onWarehouseChanged,
    required this.onCategoryChanged,
    required this.warehouses,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: loc.searchProducts,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: loc.warehouse,
                      hintText: loc.allWarehouses,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    value: null,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(loc.allWarehouses),
                      ),
                      ...warehouses.map((warehouse) {
                        return DropdownMenuItem<String>(
                          value: warehouse,
                          child: Text(
                            warehouse,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: onWarehouseChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: loc.category,
                      hintText: loc.allCategories,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    value: null,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(loc.allCategories),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
