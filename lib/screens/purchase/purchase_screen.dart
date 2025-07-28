import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/purchase.dart';
import '../../themes/app_theme.dart';
import '../../widgets/search_bar.dart';
import 'dialogs/purchase_form_dialog.dart';
import 'widgets/purchase_details_sheet.dart';
import 'widgets/purchase_table.dart';
import 'dialogs/purchase_filter_dialog.dart';
import 'controllers/purchase_screen_controller.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _searchController = TextEditingController();
  late final PurchaseScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseScreenController();
    _controller.initialize();
    
    // Add listener to search controller
    _searchController.addListener(() {
      if (_controller.searchQuery != _searchController.text) {
        _controller.updateSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PurchaseScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: _buildAppBar(loc, controller),
            body: _buildBody(loc, controller),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddPurchaseDialog(context),
              tooltip: loc.addPurchase,
              heroTag: "add_purchase",
              icon: const Icon(Icons.add),
              label: Text(loc.addPurchase),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations loc, PurchaseScreenController controller) {
    return AppBar(
      title: controller.isSearching
          ? CommonSearchBar(
              controller: _searchController,
              debounceDuration: const Duration(milliseconds: 500),
              isLoading: controller.isLoading,
              onChanged: controller.updateSearchQuery,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onCancel: () {
                controller.setSearching(false);
                _searchController.clear();
                controller.updateSearchQuery('');
              },
              hintText: loc.searchPurchases,
            )
          : _buildTitle(loc, controller),
      actions: _buildActions(loc, controller),
    );
  }

  Widget _buildTitle(AppLocalizations loc, PurchaseScreenController controller) {
    return Row(
      children: [
        Icon(Icons.shopping_cart, size: 24, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          loc.purchases,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'VazirBold',
          ),
        ),
        if (controller.purchases.isNotEmpty) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${controller.purchases.length}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(AppLocalizations loc, PurchaseScreenController controller) {
    if (controller.isSearching) return [];

    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: loc.refreshPurchases,
        onPressed: controller.isLoading ? null : controller.refresh,
      ),
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: loc.search,
        onPressed: () => controller.setSearching(true),
      ),
      IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.filter_list),
            if (controller.hasActiveFilters)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        tooltip: controller.hasActiveFilters ? loc.activeFilters : loc.filter,
        onPressed: () => _showFilterDialog(controller),
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildBody(AppLocalizations loc, PurchaseScreenController controller) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: controller.isLoading && controller.purchases.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading purchases...'),
                ],
              ),
            )
          : controller.purchases.isEmpty
              ? _buildEmptyState(loc)
              : _buildPurchaseList(controller),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            loc.noPurchasesFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'VazirBold',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.changeSearchCriteria,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(PurchaseScreenController controller) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80), // Add bottom padding for FAB
        child: Column(
          children: [
            PurchaseTable(
              purchases: controller.purchases,
              onEdit: _showEditPurchaseDialog,
              onDelete: _deletePurchase,
              onDetails: _showPurchaseDetails,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(PurchaseScreenController controller) {
    String? tmpSupplier = controller.selectedSupplier;
    String? tmpCurrency = controller.selectedCurrency;
    DateTime? tmpDate = controller.selectedDate;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return PurchaseFilterDialog(
              selectedSupplier: tmpSupplier,
              selectedCurrency: tmpCurrency,
              selectedDate: tmpDate,
              supplierOptions: controller.supplierOptions,
              currencyOptions: controller.currencyOptions,
              onChanged: ({String? supplier, String? currency, DateTime? date}) {
                setModalState(() {
                  if (supplier != null) tmpSupplier = supplier;
                  if (currency != null) tmpCurrency = currency;
                  if (date != null) tmpDate = date;
                });
              },
              onReset: () {
                setModalState(() {
                  tmpSupplier = null;
                  tmpCurrency = null;
                  tmpDate = null;
                });
              },
              onApply: ({supplier, currency, date}) {
                controller.applyFilters(
                  supplier: tmpSupplier,
                  currency: tmpCurrency,
                  date: tmpDate,
                );
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PurchaseFormDialog(),
    );
  }

  void _showEditPurchaseDialog(Map<String, dynamic> purchase) {
    final purchaseObj = Purchase.fromMap(purchase);
    showDialog(
      context: context,
      builder: (context) => PurchaseFormDialog(purchase: purchaseObj),
    );
  }

  void _showPurchaseDetails(Map<String, dynamic> purchase) {
    final purchaseObj = Purchase.fromMap(purchase);
    showDialog(
      context: context,
      builder: (context) => PurchaseDetailsSheet(purchase: purchaseObj),
    );
  }

  Future<void> _deletePurchase(Map<String, dynamic> purchase) async {
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
        await _controller.deletePurchase(purchase);
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
}
