import 'package:BusinessHubPro/models/purchase.dart';
import 'package:BusinessHubPro/models/purchase_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/purchase_provider.dart';
import '../../themes/app_theme.dart';
import 'dialogs/purchase_form_dialog.dart';
import 'widgets/purchase_details_sheet.dart';
import '../../providers/account_provider.dart';
import '../../providers/inventory_provider.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchases() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<PurchaseProvider>();
      await provider.loadPurchases(refresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filter purchases based on search query
  List<Purchase> _getFilteredPurchases(PurchaseProvider provider) {
    return provider.purchases.where((purchase) {
      final matchesSearch = purchase.invoiceNumber!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          final purchases = _getFilteredPurchases(provider);

          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, provider),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : purchases.isEmpty
                            ? _buildEmptyState(provider)
                            : _buildPurchasesList(purchases, provider),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPurchaseDialog(context),
        tooltip: loc.addPurchase,
        heroTag: "add_purchase",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PurchaseProvider provider) {
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
                  loc.purchases,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: loc.refreshPurchases,
                  onPressed: _isLoading ? null : () => _loadPurchases(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: loc.searchPurchases,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PurchaseProvider provider) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            loc.noPurchasesFound,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            loc.changeSearchCriteria,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _loadPurchases(),
            icon: const Icon(Icons.refresh),
            label: Text(loc.refreshPurchases),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesList(
      List<Purchase> purchases, PurchaseProvider provider) {
    return RefreshIndicator(
      onRefresh: _loadPurchases,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 80,
        ),
        itemCount: purchases.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final purchase = purchases[index];
          return PurchaseCard(
            purchase: purchase,
            onTap: () => _showPurchaseDetails(purchase, provider),
          );
        },
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PurchaseFormDialog(),
    );
  }

  void _showPurchaseDetails(Purchase purchase, PurchaseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PurchaseDetailsSheet(purchase: purchase),
    );
  }
}

class PurchaseCard extends StatefulWidget {
  final Purchase purchase;
  final VoidCallback onTap;

  const PurchaseCard({
    Key? key,
    required this.purchase,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<PurchaseCard> {
  late Future<List<PurchaseItem>> _itemsFuture;
  late Future<Map<String, dynamic>?> _supplierFuture;

  @override
  void initState() {
    super.initState();
    if (widget.purchase.id != null) {
      _itemsFuture = context.read<PurchaseProvider>().getPurchaseItems(widget.purchase.id);
      _supplierFuture = context.read<AccountProvider>().getAccountById(widget.purchase.supplierId);
    } else {
      _itemsFuture = Future.value([]);
      _supplierFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<PurchaseItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder<Map<String, dynamic>?>(
          future: _supplierFuture,
          builder: (context, supplierSnapshot) {
            final supplier = supplierSnapshot.data;

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  widget.purchase.invoiceNumber!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${loc.date}: ${widget.purchase.date.toIso8601String().split('T')[0]}'),
                    Text('${loc.supplier}: ${supplier?['name'] ?? ''}'),
                    Text(
                      '${loc.total}: ${widget.purchase.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          children: items.map((item) {
                            return Chip(
                              label: Text(item.productName ?? 'Unknown Product'),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                onTap: widget.onTap,
              ),
            );
          },
        );
      },
    );
  }
}
