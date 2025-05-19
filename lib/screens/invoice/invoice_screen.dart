import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

    // Initialize invoice data with error handling
    Future.microtask(() {
      if (!_isDisposed) {
        try {
          context.read<InvoiceProvider>().initialize();
        } catch (e) {
          debugPrint('Error initializing invoice provider: $e');
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Invoices'),
            Tab(text: 'Overdue'),
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
              // All Invoices Tab - Wrap in error boundaries
              ErrorHandler(
                child: InvoiceList(
                  invoices: provider.invoices,
                  onPaymentRecorded: (invoice, amount) async {
                    try {
                      await provider.recordPayment(invoice.id!, amount);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, 'Failed to record payment: $e');
                    }
                  },
                  onInvoiceFinalized: (invoice) async {
                    try {
                      await provider.finalizeInvoice(invoice);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, 'Failed to finalize invoice: $e');
                    }
                  },
                ),
              ),

              // Overdue Invoices Tab - Wrap in error boundaries
              ErrorHandler(
                child: InvoiceList(
                  invoices: provider.overdueInvoices,
                  showOverdueWarning: true,
                  onPaymentRecorded: (invoice, amount) async {
                    try {
                      await provider.recordPayment(invoice.id!, amount);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, 'Failed to record payment: $e');
                    }
                  },
                  onInvoiceFinalized: (invoice) async {
                    try {
                      await provider.finalizeInvoice(invoice);
                    } catch (e) {
                      _showErrorSnackbar(
                          context, 'Failed to finalize invoice: $e');
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
        child: const Icon(Icons.add),
        tooltip: 'Create Invoice',
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

// Error handler widget to prevent crashes from propagating
class ErrorHandler extends StatelessWidget {
  final Widget child;

  const ErrorHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      // Set up error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('UI Rendering Error: ${details.exception}');
      };

      return child;
    });
  }
}
