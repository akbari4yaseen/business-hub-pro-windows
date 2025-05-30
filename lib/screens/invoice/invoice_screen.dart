import 'package:BusinessHubPro/utils/invoice.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/account_provider.dart';
import 'create_invoice_screen.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../widgets/search_bar.dart';

import '../../providers/invoice_provider.dart';
import '../../widgets/invoice/invoice_list.dart';
import '../../models/invoice.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isAtTop = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    // Initialize invoice provider after build context is available
    Future.microtask(() {
      if (mounted) {
        context.read<InvoiceProvider>().initialize();
        context.read<AccountProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InvoiceProvider>().loadInvoices();
    }
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  void _showFilterModal() {
    final provider = context.read<InvoiceProvider>();
    String? tmpStatus = provider.selectedStatus;
    DateTime? tmpStartDate = provider.selectedStartDate;
    DateTime? tmpEndDate = provider.selectedEndDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.filter,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: tmpStatus,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.status,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppLocalizations.of(context)!.all),
                      ),
                      ...InvoiceStatus.values.map((status) => DropdownMenuItem(
                            value: status.toString().split('.').last,
                            child: Text(status
                                .localizedName(AppLocalizations.of(context)!)),
                          )),
                    ],
                    onChanged: (value) => setState(() => tmpStatus = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.startDate,
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: tmpStartDate != null
                                ? dFormatter.formatLocalizedDate(
                                    context, tmpStartDate.toString())
                                : null,
                          ),
                          onTap: () async {
                            final result = await pickLocalizedDate(
                              context: context,
                              initialDate: tmpStartDate ?? DateTime.now(),
                            );
                            if (result != null) {
                              setState(() {
                                tmpStartDate = result;
                                // If end date is before start date, clear it
                                if (tmpEndDate != null &&
                                    tmpEndDate!.isBefore(tmpStartDate!)) {
                                  tmpEndDate = null;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.endDate,
                            prefixIcon:
                                const Icon(Icons.calendar_month_outlined),
                          ),
                          controller: TextEditingController(
                            text: tmpEndDate != null
                                ? dFormatter.formatLocalizedDate(
                                    context, tmpEndDate.toString())
                                : null,
                          ),
                          onTap: () async {
                            final result = await pickLocalizedDate(
                              context: context,
                              initialDate: tmpEndDate ??
                                  (tmpStartDate ?? DateTime.now()),
                            );
                            if (result != null) {
                              setState(() => tmpEndDate = result);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            provider.resetFilters();
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context)!.reset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply filters to match exact dates
                            provider.applyFilters(
                              status: tmpStatus,
                              startDate: tmpStartDate,
                              endDate: tmpEndDate,
                            );
                            Navigator.pop(context);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.applyFilters),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  context.read<InvoiceProvider>().searchInvoices(value);
                },
                onCancel: () {
                  setState(() => _isSearching = false);
                  _searchController.clear();
                  context.read<InvoiceProvider>().searchInvoices('');
                },
                hintText: loc.search,
              )
            : Text(loc.invoices),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.allInvoices),
            Tab(text: loc.overdue),
          ],
        ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
                _searchController.clear();
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterModal,
            ),
          ],
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: () => provider.loadInvoices(refresh: true),
                child: _buildInvoiceList(context, loc, provider.invoices),
              ),
              RefreshIndicator(
                onRefresh: () => provider.loadInvoices(refresh: true),
                child: _buildInvoiceList(
                  context,
                  loc,
                  provider.overdueInvoices,
                  showOverdueWarning: true,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "create_invoice_fab",
        mini: !_isAtTop,
        onPressed: () {
          if (_isAtTop) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreateInvoiceScreen(),
              ),
            );
          } else {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        },
        tooltip: loc.createInvoice,
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
            size: 18),
      ),
    );
  }

  Widget _buildInvoiceList(
    BuildContext context,
    AppLocalizations loc,
    List<Invoice> invoices, {
    bool showOverdueWarning = false,
  }) {
    final provider = context.read<InvoiceProvider>();
    return InvoiceList(
      invoices: invoices,
      showOverdueWarning: showOverdueWarning,
      onPaymentRecorded: (invoice, amount) async {
        try {
          await provider.recordPayment(
              invoice.id!, amount, loc.paymentForInvoice);
        } catch (e) {
          _showErrorSnackbar(context, loc.failedRecordPayment(e.toString()));
        }
      },
      onInvoiceFinalized: (invoice) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.confirmFinalizeInvoice),
            content: Text(loc.finalizeInvoiceConfirmation),
            actions: [
              TextButton(
                child: Text(loc.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(loc.confirm),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await provider.finalizeInvoice(invoice, loc.invoice);
          } catch (e) {
            _showErrorSnackbar(
                context, loc.failedFinalizeInvoice(e.toString()));
          }
        }
      },
      scrollController: _scrollController,
      isLoading: provider.isLoading,
      hasMore: provider.hasMore,
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
