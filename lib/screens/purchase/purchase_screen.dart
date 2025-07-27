import 'package:BusinessHubPro/models/purchase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dialogs/purchase_form_dialog.dart';
import 'widgets/purchase_details_sheet.dart';
import '../../providers/purchase_provider.dart';
import '../../themes/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../../utils/date_formatters.dart';

final _amountFormatter = NumberFormat('#,##0.##');

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
                  color: Colors.black.withValues(alpha: 0.1),
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
    showDialog(
      context: context,
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
  List<PurchaseItem> _items = [];
  Map<String, dynamic>? _supplier;
  bool _isLoadingItems = true;
  bool _isLoadingSupplier = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.purchase.id != null) {
      // Load items and supplier data asynchronously
      _loadItems();
      _loadSupplier();
    } else {
      setState(() {
        _isLoadingItems = false;
        _isLoadingSupplier = false;
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await context
          .read<PurchaseProvider>()
          .getPurchaseItems(widget.purchase.id);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _loadSupplier() async {
    try {
      final supplier = await context
          .read<AccountProvider>()
          .getAccountById(widget.purchase.supplierId);
      if (mounted) {
        setState(() {
          _supplier = supplier;
          _isLoadingSupplier = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSupplier = false;
        });
      }
    }
  }

  Future<void> _deletePurchase() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deletePurchase),
        content: Text(loc.deletePurchaseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context
            .read<PurchaseProvider>()
            .deletePurchase(widget.purchase.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.purchaseDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editPurchase() {
    showDialog(
      context: context,
      builder: (context) => PurchaseFormDialog(purchase: widget.purchase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.purchase.invoiceNumber!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPurchase();
                    break;
                  case 'delete':
                    _deletePurchase();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text(loc.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(loc.delete,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${loc.date}: ${formatLocalizedDate(context, widget.purchase.date.toString())}'),
            Text(
                '${loc.supplier}: ${_supplier?['name'] ?? (_isLoadingSupplier ? 'Loading...' : '')}'),
            Text(
              '${loc.total}: \u200E${_amountFormatter.format(widget.purchase.totalAmount)} ${widget.purchase.currency}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  children: _items.map((item) {
                    return Chip(
                      label: Text(item.productName ?? 'Unknown Product'),
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ),
            if (_isLoadingItems)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Loading items...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }
}
