import 'package:BusinessHubPro/utils/transaction_share_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../../utils/utilities.dart';
import '../../../widgets/search_bar.dart';
import '../../../utils/account_share_helper.dart';
import '../../../widgets/auth_widget.dart';
import '../../../widgets/transaction/transaction_details_widget.dart';
import '../../../widgets/journal/journal_form_dialog.dart';
import '../../../widgets/journal/journal_filter_dialog.dart';
import '../../../widgets/transaction/transaction_print_settings_dialog.dart';
import '../../../database/journal_db.dart';
import '../../../database/account_db.dart';
import 'controllers/transactions_screen_controller.dart';
import 'widgets/transaction_list.dart';
import 'print_transactions.dart';

class TransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const TransactionsScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final TransactionsScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransactionsScreenController(widget.account);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        !_controller.isLoadingMore &&
        _controller.hasMore &&
        !_controller.isLoading) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<TransactionsScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: _buildAppBar(loc, controller),
            body: _buildBody(loc, controller),
            floatingActionButton: FloatingActionButton(
              heroTag: 'transaction_add_fab',
              mini: false,
              child: const FaIcon(FontAwesomeIcons.plus, size: 18),
              onPressed: () => _showAddJournalDialog(controller),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AppLocalizations loc, TransactionsScreenController controller) {
    return AppBar(
      title: controller.isSearching
          ? CommonSearchBar(
              controller: _searchController,
              debounceDuration: const Duration(milliseconds: 500),
              isLoading: controller.isLoading,
              onChanged: controller.updateSearchQuery,
              onSubmitted: (_) =>
                  controller.updateSearchQuery(_searchController.text),
              onCancel: () {
                _searchController.clear();
                controller.setSearching(false);
                controller.updateSearchQuery('');
              },
              hintText: loc.search,
            )
          : Text(
              getLocalizedSystemAccountName(
                  context, controller.account['name']),
              style: const TextStyle(fontSize: 18),
            ),
      actions: _buildActions(loc, controller),
    );
  }

  List<Widget> _buildActions(
      AppLocalizations loc, TransactionsScreenController controller) {
    if (controller.isSearching) return [];

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => controller.setSearching(true),
        tooltip: loc.search,
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refresh,
        tooltip: loc.refresh,
      ),
      PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(value, controller),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'filter',
            child: ListTile(
              leading: const Icon(Icons.filter_list),
              title: Text(loc.filter),
            ),
          ),
          PopupMenuItem(
            value: 'print',
            child: ListTile(
              leading: const Icon(Icons.print),
              title: Text(loc.print),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'share',
            child: ListTile(
              leading: const FaIcon(FontAwesomeIcons.shareNodes),
              title: Text(loc.shareBalance),
            ),
          ),
          PopupMenuItem(
            value: 'copy_balance',
            child: ListTile(
              leading: const FaIcon(FontAwesomeIcons.copy),
              title: Text(loc.copyBalance),
            ),
          ),
          PopupMenuItem(
            value: 'whatsapp',
            child: ListTile(
              leading: const FaIcon(FontAwesomeIcons.whatsapp),
              title: Text(loc.sendBalance),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildBody(
      AppLocalizations loc, TransactionsScreenController controller) {
    if (controller.isLoading && controller.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildTransactionList(controller);
  }

  Widget _buildTransactionList(TransactionsScreenController controller) {
    return TransactionList(
      transactions: controller.transactions,
      isLoading: controller.isLoading,
      hasMore: controller.hasMore,
      scrollController: _scrollController,
      onDetails: (transaction) => _showTransactionDetails(transaction),
      onEdit: (transaction) => _handleEditTransaction(transaction, controller),
      onDelete: (transaction) =>
          _handleDeleteTransaction(transaction, controller),
      onShare: (transaction) => _shareTransaction(transaction),
      onCopy: (transaction) => _copyTransaction(transaction),
      onSend: (transaction) => _sendTransaction(transaction),
      amountFormatter: controller.amountFormatter,
      balances: controller.balances,
    );
  }

  Future<void> _handleMenuAction(
      String action, TransactionsScreenController controller) async {
    final loc = AppLocalizations.of(context)!;
    final accountName = controller.account['name'] as String? ?? '';

    // Format balances to match what buildShareMessage expects
    final Map<String, dynamic> formattedBalances = {};
    controller.balances.forEach((currency, data) {
      formattedBalances[currency] = {
        'currency': currency,
        'summary': {
          'balance': data['summary']?['balance'] ?? 0.0,
          'credit': data['summary']?['credit'] ?? 0.0,
          'debit': data['summary']?['debit'] ?? 0.0,
        }
      };
    });

    final account = {
      ...controller.account,
      'name': accountName,
      'balances': formattedBalances,
    };

    switch (action) {
      case 'filter':
        _showFilterDialog(controller);
        break;
      case 'print':
        _onPrintPressed(controller);
        break;
      case 'share':
        await shareAccountBalances(context, account);
        break;
      case 'copy_balance':
        try {
          final message = await buildShareMessage(context, account);
          await Clipboard.setData(ClipboardData(text: message));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.copiedToClipboard)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.error)),
            );
          }
        }
        break;
      case 'whatsapp':
        await shareAccountBalances(
          context,
          account,
          viaWhatsApp: true,
        );
        break;
    }
  }

  void _showFilterDialog(TransactionsScreenController controller) {
    String? tmpType = controller.selectedType;
    String? tmpCurrency = controller.selectedCurrency;
    DateTime? tmpDate = controller.selectedDate;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return JournalFilterDialog(
              selectedType: tmpType,
              selectedCurrency: tmpCurrency,
              selectedDate: tmpDate,
              typeOptions: const ['all', 'credit', 'debit'],
              currencyOptions: controller.currencyOptions,
              onChanged: ({String? type, String? currency, DateTime? date}) {
                setModalState(() {
                  if (type != null) tmpType = type;
                  if (currency != null) tmpCurrency = currency;
                  if (date != null) tmpDate = date;
                });
              },
              onReset: () {
                setModalState(() {
                  tmpType = null;
                  tmpCurrency = null;
                  tmpDate = null;
                });
              },
              onApply: ({type, currency, date}) {
                controller.applyFilters(
                  type: tmpType,
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

  void _onPrintPressed(TransactionsScreenController controller) async {
    if (controller.currencyOptions.isEmpty) {
      await controller.refresh();
    }

    final result = await showDialog<PrintSettings>(
      context: context,
      builder: (_) => PrintSettingsDialog(
        typeOptions: ['all', 'credit', 'debit'],
        currencyOptions: controller.currencyOptions,
        initialType: controller.selectedType ?? 'all',
        initialCurrency: controller.selectedCurrency ?? 'all',
        initialStart: null,
        initialEnd: null,
      ),
    );
    if (result == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.preparingPrint),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      // Get all transactions for the account
      final allTransactions = await AccountDBHelper()
          .getTransactionsForPrint(controller.account['id']);

      // Filter transactions based on print settings
      List<Map<String, dynamic>> filteredTransactions =
          allTransactions.where((tx) {
        // Filter by date range
        if (result.startDate != null || result.endDate != null) {
          final txDate = DateTime.parse(tx['date']);
          final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);

          if (result.startDate != null) {
            final startDateOnly = DateTime(result.startDate!.year,
                result.startDate!.month, result.startDate!.day);
            if (txDateOnly.isBefore(startDateOnly)) {
              return false;
            }
          }

          if (result.endDate != null) {
            final endDateOnly = DateTime(result.endDate!.year,
                result.endDate!.month, result.endDate!.day);
            if (txDateOnly.isAfter(endDateOnly)) {
              return false;
            }
          }
        }

        // Filter by transaction type
        if (result.transactionType != null && result.transactionType != 'all') {
          if (tx['transaction_type'] != result.transactionType) {
            return false;
          }
        }

        // Filter by currency
        if (result.currency != null && result.currency != 'all') {
          if (tx['currency'] != result.currency) {
            return false;
          }
        }

        return true;
      }).toList();

      // Call the print service
      await PrintTransactions.printTransactions(
        context,
        controller.account,
        transactions: filteredTransactions,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (_) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _shareTransaction(Map<String, dynamic> transaction) async {
    await TransactionShareHelper.shareTransaction(
      context,
      transaction,
      accountName: _controller.account['name'] as String?,
    );
  }

  Future<void> _copyTransaction(Map<String, dynamic> transaction) async {
    await TransactionShareHelper.copyTransaction(
      context,
      transaction,
      accountName: _controller.account['name'] as String?,
    );
  }

  Future<void> _sendTransaction(Map<String, dynamic> transaction) async {
    final phoneNumber = _controller.account['phone'] as String?;
    await TransactionShareHelper.sendTransaction(
      context,
      transaction,
      phoneNumber: phoneNumber,
      accountName: _controller.account['name'] as String?,
    );
  }

  Future<void> _showAddJournalDialog(
      TransactionsScreenController controller) async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => JournalFormDialog(
        initialAccountId: controller.account['id'],
        initialAccountName: controller.account['name'],
        onSave: (journalData) async {
          try {
            await controller.addJournal(journalData);
            Navigator.of(dialogContext).pop(journalData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.errorSavingJournal),
                ),
              );
            }
          }
        },
      ),
    );

    if (result != null && mounted) {
      await controller.refresh();
    }
  }

  Future<void> _handleEditTransaction(Map<String, dynamic> transaction,
      TransactionsScreenController controller) async {
    if (transaction['transaction_group'] != 'journal') return;

    try {
      final journal =
          await JournalDBHelper().getJournalById(transaction['transaction_id']);
      if (journal == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.transactionNotFound)),
          );
        }
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => JournalFormDialog(
          journal: journal,
          onSave: (journalData) async {
            try {
              await controller.editJournal(journal, journalData);
              Navigator.of(dialogContext).pop(journalData);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.transactionEditError)),
                );
              }
            }
          },
        ),
      );

      if (result != null && mounted) {
        await controller.refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.transactionEditError)),
        );
      }
    }
  }

  Future<void> _handleDeleteTransaction(Map<String, dynamic> transaction,
      TransactionsScreenController controller) async {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AuthWidget(
        actionReason: loc.deleteJournalAuthMessage,
        onAuthenticated: () {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (confirmCtx) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AlertDialog(
                  title: Text(loc.confirmDelete),
                  content: Text(loc.confirmDeleteTransaction),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(confirmCtx).pop(),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(confirmCtx).pop();
                        try {
                          await controller.deleteTransaction(transaction);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.transactionDeleteError)),
                            );
                          }
                        }
                      },
                      child: Text(
                        loc.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
