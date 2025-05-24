import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/inventory_provider.dart';
import '../models/category.dart' as inventory_models;

class CategoryDialog extends StatelessWidget {
  final inventory_models.Category? category;

  const CategoryDialog({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');

    return AlertDialog(
      title: Text(isEditing ? loc.editCategory : loc.addCategory),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: loc.categoryName),
          ),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: loc.descriptionOptional),
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
            if (nameController.text.trim().isEmpty) return;

            final newCategory = inventory_models.Category(
              id: category?.id,
              name: nameController.text.trim(),
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
            );

            final provider = context.read<InventoryProvider>();
            isEditing
                ? provider.updateCategory(newCategory)
                : provider.addCategory(newCategory);

            Navigator.of(context).pop();
          },
          child: Text(isEditing ? loc.save : loc.add),
        ),
      ],
    );
  }
} 