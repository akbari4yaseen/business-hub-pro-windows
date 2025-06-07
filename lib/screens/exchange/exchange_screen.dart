import 'package:flutter/material.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExchange(Exchange exchange) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exchange'),
        content: const Text('Are you sure you want to delete this exchange?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _exchangeDb.deleteExchange(exchange.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exchange deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting exchange: ${e.toString()}')),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange'),
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
