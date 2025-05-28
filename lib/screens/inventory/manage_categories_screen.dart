import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/inventory_provider.dart';
import '../../models/category.dart' as inventory_models;
import '../../widgets/category_dialog.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.manageCategories),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          if (categories.isEmpty) {
            return Center(
              child: Text(
                loc.noCategoriesFound,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: category.description != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            category.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCategoryDialog(context, category: category);
                      } else if (value == 'delete') {
                        _confirmDeleteCategory(context, category);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: colorScheme.primary),
                          title: Text(loc.edit),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: colorScheme.error),
                          title: Text(loc.delete),
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                  ),
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

  Future<void> _showCategoryDialog(BuildContext context,
      {inventory_models.Category? category}) async {
    await showDialog(
      context: context,
      builder: (context) => CategoryDialog(category: category),
    );
  }

  void _confirmDeleteCategory(
      BuildContext context, inventory_models.Category category) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteCategory),
        content: Text(loc.confirmDeleteCategory(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () {
              context.read<InventoryProvider>().deleteCategory(category.id!);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.categoryDeleted)),
              );
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
