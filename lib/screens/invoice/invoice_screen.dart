import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'create_invoice_screen.dart';

import '../../providers/invoice_provider.dart';
import '../../widgets/invoice/invoice_list.dart';
import '../../models/invoice.dart';

class InvoiceScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const InvoiceScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize invoice provider after build context is available
    Future.microtask(() {
      if (mounted) {
        context.read<InvoiceProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        title: Text(local.invoices),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: local.allInvoices),
            Tab(text: local.overdue),
          ],
        ),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInvoiceList(context, local, provider.invoices),
              _buildInvoiceList(
                context,
                local,
                provider.overdueInvoices,
                showOverdueWarning: true,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "create_invoice_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateInvoiceScreen(),
            ),
          );
        },
        tooltip: local.createInvoice,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceList(
    BuildContext context,
    AppLocalizations local,
    List<Invoice> invoices, {
    bool showOverdueWarning = false,
  }) {
    final provider = context.read<InvoiceProvider>();

    return InvoiceList(
      invoices: invoices,
      showOverdueWarning: showOverdueWarning,
      onPaymentRecorded: (invoice, amount) async {
        try {
          await provider.recordPayment(invoice.id!, amount);
        } catch (e) {
          _showErrorSnackbar(context, local.failedRecordPayment(e.toString()));
        }
      },
      onInvoiceFinalized: (invoice) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(local.confirmFinalizeInvoice),
            content: Text(local.finalizeInvoiceConfirmation),
            actions: [
              TextButton(
                child: Text(local.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(local.confirm),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await provider.finalizeInvoice(invoice);
          } catch (e) {
            _showErrorSnackbar(
                context, local.failedFinalizeInvoice(e.toString()));
          }
        }
      },
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
