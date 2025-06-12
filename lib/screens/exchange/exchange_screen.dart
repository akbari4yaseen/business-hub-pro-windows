import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/exchange_db.dart';
import '../../models/exchange.dart';
import '../../widgets/exchange_list_widget.dart';
import 'exchange_form_screen.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  _ExchangeScreenState createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _exchangeDb = ExchangeDBHelper();
  bool _isLoading = false;

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _exchangeDb.getExchanges();
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorRefreshingData}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExchange(Exchange exchange) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteExchangeTitle),
        content: Text(loc.deleteExchangeConfirm),
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

    if (confirmed == true) {
      try {
        await _exchangeDb.deleteExchange(exchange.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.exchangeDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.errorDeletingExchange}: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showExchangeForm([Exchange? editingExchange]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExchangeFormScreen(
          exchange: editingExchange,
        ),
      ),
    );

    if (result == true && mounted) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.exchange),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: ExchangeListWidget(
          onEdit: _showExchangeForm,
          onDelete: _deleteExchange,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExchangeForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
