import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../providers/inventory_provider.dart';
import '../add_product_screen.dart';
import '../manage_units_screen.dart';
import '../manage_categories_screen.dart';
import '../widgets/product_details_sheet.dart';
import '../../../themes/app_theme.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showInactive = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter products based on search query and filters
  List<dynamic> _getFilteredProducts(InventoryProvider provider) {
    return provider.products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null ||
          provider
              .getCategoryName(product.categoryId)
              .contains(_selectedCategory!);
      final matchesStatus = _showInactive || product.isActive;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final products = _getFilteredProducts(provider);

          return Column(
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: products.isEmpty
                    ? _buildEmptyState(provider)
                    : _buildProductsList(products, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        tooltip: loc.addProduct,
        heroTag: "add_product_product",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.products,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: loc.refreshProducts,
                          onPressed: () => provider.refreshProducts(),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: () => _showManageCategoriesDialog(context),
                          icon: const Icon(Icons.category, size: 16),
                          label: Text(loc.categories),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: () => _showManageUnitsDialog(context),
                          icon: const Icon(Icons.straighten, size: 16),
                          label: Text(loc.units),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: loc.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: loc.category, // e.g., "Category"
                      hintText: loc.allCategories, // e.g., "All Categories"
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    value: _selectedCategory,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(loc.allCategories),
                      ),
                      ...provider.categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: Text(loc.showInactive),
                    value: _showInactive,
                    onChanged: (value) => setState(() => _showInactive = value),
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 12),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(InventoryProvider provider) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your search criteria or add new products',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.refreshProducts(),
            icon: const Icon(Icons.refresh),
            label: Text(loc.refreshProducts),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(
      List<dynamic> products, InventoryProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, provider);
      },
    );
  }

  Widget _buildProductCard(dynamic product, InventoryProvider provider) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: product.isActive
            ? BorderSide.none
            : const BorderSide(color: Colors.grey, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: product.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(provider.getCategoryName(product.categoryId)),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text('${loc.unit}: ${provider.getUnitName(product.unitId)}'),
              ],
            ),
            if (product.sku != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${loc.sku}: ${product.sku}'),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!product.isActive)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(loc.inactive),
                  backgroundColor: Colors.grey,
                  labelStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(loc.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: product.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        product.isActive ? Icons.toggle_off : Icons.toggle_on,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(product.isActive ? loc.deactivate : loc.activate),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(loc.delete,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleProductAction(value, product),
            ),
          ],
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
    );
  }

  void _showManageUnitsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageUnitsScreen()),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
  }

  void _handleProductAction(String action, dynamic product) async {
    final provider = context.read<InventoryProvider>();
    final loc = AppLocalizations.of(context)!;

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddProductScreen(product: product)),
        );
        break;

      case 'activate':
      case 'deactivate':
        try {
          final updatedProduct =
              product.copyWith(isActive: action == 'activate');
          await provider.updateProduct(updatedProduct);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${loc.product} ${action == 'activate' ? 'activated' : 'deactivated'} successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.error}: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.deleteProduct),
            content: Text('Are you sure you want to delete ${product.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.delete),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            await provider.deleteProduct(product.id);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${loc.error}: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;
    }
  }

  void _showProductDetails(dynamic product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ProductDetailsSheet(product: product),
    );
  }
}
