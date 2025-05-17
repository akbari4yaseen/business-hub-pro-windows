import 'package:flutter/material.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products...',
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Warehouse',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    value: null,
                    hint: const Text('All Warehouses'),
                    items: warehouses.map((warehouse) {
                      return DropdownMenuItem(
                        value: warehouse,
                        child: Text(
                          warehouse,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onWarehouseChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    value: null,
                    hint: const Text('All Categories'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
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