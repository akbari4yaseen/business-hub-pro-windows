import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/category.dart' as inventory_models;

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.manageCategories)),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          if (categories.isEmpty) {
            return Center(
              child: Text(loc.noCategoriesFound),
            );
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: category.description != null
                    ? Text(category.description!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showCategoryDialog(context, category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _confirmDeleteCategory(context, category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
        tooltip: loc.addCategory,
      ),
    );
  }

  void _showCategoryDialog(BuildContext context,
      {inventory_models.Category? category}) {
    final loc = AppLocalizations.of(context)!;
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  void _confirmDeleteCategory(
      BuildContext context, inventory_models.Category category) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteCategory),
        content: Text(
          loc.confirmDeleteCategory(category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<InventoryProvider>().deleteCategory(category.id!);
              Navigator.of(context).pop();
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
