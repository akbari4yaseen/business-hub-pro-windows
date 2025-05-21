import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/inventory_provider.dart';
import '../add_product_screen.dart';
import '../manage_units_screen.dart';
import '../manage_categories_screen.dart';
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
        tooltip: 'Add Product',
        heroTag: "add_product_product",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
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
                const Text(
                  'Products',
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
                          tooltip: 'Refresh Products',
                          onPressed: () => provider.refreshProducts(),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: () => _showManageCategoriesDialog(context),
                          icon: const Icon(Icons.category, size: 16),
                          label: const Text('Categories'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: () => _showManageUnitsDialog(context),
                          icon: const Icon(Icons.straighten, size: 16),
                          label: const Text('Units'),
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    value: _selectedCategory,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...provider.categories
                          .map((c) => DropdownMenuItem<String>(
                                value: c.name,
                                child: Text(c.name),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Inactive'),
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
            label: const Text('Refresh Products'),
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
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text('Unit: ${provider.getUnitName(product.unitId)}'),
              ],
            ),
            if (product.sku != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('SKU: ${product.sku}'),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!product.isActive)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text('Inactive'),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
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
                      Text(product.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
                  'Product ${action == 'activate' ? 'activated' : 'deactivated'} successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete ${product.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
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
                content: Text('Error: $e'),
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
    final provider = context.read<InventoryProvider>();
    final currentStock = provider.getCurrentStockForProduct(product.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(product.name)),
            if (!product.isActive)
              const Chip(
                label: Text('Inactive'),
                backgroundColor: Colors.grey,
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailCard(
                'Basic Information',
                [
                  _buildDetailRow(
                      'Category', provider.getCategoryName(product.categoryId)),
                  _buildDetailRow('Unit', provider.getUnitName(product.unitId)),
                  if (product.sku != null) _buildDetailRow('SKU', product.sku),
                  if (product.barcode != null)
                    _buildDetailRow('Barcode', product.barcode),
                ],
              ),
              if (product.description != null && product.description.isNotEmpty)
                _buildDetailCard(
                  'Description',
                  [_buildDetailRow('', product.description)],
                ),
              _buildDetailCard(
                'Stock Settings',
                [
                  _buildDetailRow(
                      'Min Stock', product.minStock?.toString() ?? 'Not set'),
                  _buildDetailRow(
                      'Max Stock', product.maxStock?.toString() ?? 'Not set'),
                  _buildDetailRow('Reorder Point',
                      product.reorderPoint?.toString() ?? 'Not set'),
                ],
              ),
              if (product.notes != null && product.notes.isNotEmpty)
                _buildDetailCard(
                  'Notes',
                  [_buildDetailRow('', product.notes)],
                ),
              _buildDetailCard(
                'Current Stock',
                [],
                footer: currentStock.isEmpty
                    ? const Text('No stock information available')
                    : Column(
                        children: currentStock
                            .map((stock) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(stock['warehouse_name']),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${stock['quantity']} ${provider.getUnitName(product.unitId)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleProductAction('edit', product);
            },
            child: const Text('Edit Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> content,
      {Widget? footer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (content.isNotEmpty) const Divider(),
            ...content,
            if (footer != null) ...[
              if (content.isNotEmpty) const SizedBox(height: 8),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
