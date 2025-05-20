import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/invoice_provider.dart';
import '../../widgets/invoice/invoice_list.dart';
import 'create_invoice_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const InvoiceScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      if (!_isDisposed) {
        try {
          context.read<InvoiceProvider>().initialize();
        } catch (e) {
          // debugPrint('Error initializing invoice provider: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
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
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              ErrorHandler(
                child: InvoiceList(
                  invoices: provider.invoices,
                  onPaymentRecorded: (invoice, amount) async {
                    try {
                      await provider.recordPayment(invoice.id!, amount);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, local.failedRecordPayment(e.toString()));
                    }
                  },
                  onInvoiceFinalized: (invoice) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(local.confirmFinalizeInvoice),
                          content: Text(local.finalizeInvoiceConfirmation),
                          actions: <Widget>[
                            TextButton(
                              child: Text(local.cancel),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: Text(local.confirm),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
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
                ),
              ),
              ErrorHandler(
                child: InvoiceList(
                  invoices: provider.overdueInvoices,
                  showOverdueWarning: true,
                  onPaymentRecorded: (invoice, amount) async {
                    try {
                      await provider.recordPayment(invoice.id!, amount);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, local.failedRecordPayment(e.toString()));
                    }
                  },
                  onInvoiceFinalized: (invoice) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(local.confirmFinalizeInvoice),
                          content: Text(local.finalizeInvoiceConfirmation),
                          actions: <Widget>[
                            TextButton(
                              child: Text(local.cancel),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: Text(local.confirm),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        tooltip: local.createInvoice,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (!_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

class ErrorHandler extends StatelessWidget {
  final Widget child;

  const ErrorHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };
      return child;
    });
  }
}
