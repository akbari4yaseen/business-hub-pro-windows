import 'package:BusinessHubPro/utils/date_formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exchange.dart';
import '../database/exchange_db.dart';

class ExchangeListWidget extends StatefulWidget {
  final Function(Exchange) onEdit;
  final Function(Exchange) onDelete;

  const ExchangeListWidget({
    Key? key,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ExchangeListWidgetState createState() => _ExchangeListWidgetState();
}

class _ExchangeListWidgetState extends State<ExchangeListWidget> {
  final _exchangeDb = ExchangeDBHelper();
  final _scrollController = ScrollController();
  List<Exchange> _exchanges = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadExchanges();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadExchanges() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final exchanges = await _exchangeDb.getExchanges(
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _exchanges.addAll(exchanges);
        _hasMore = exchanges.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exchanges: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadExchanges();
    }
  }

  Future<void> _refreshExchanges() async {
    setState(() {
      _exchanges.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadExchanges();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshExchanges,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _exchanges.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _exchanges.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final exchange = _exchanges[index];
          return Card(
            shape:
                const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            child: ListTile(
              title: Text(
                '${exchange.fromCurrency} → ${exchange.toCurrency}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount: ${NumberFormat.currency(symbol: exchange.fromCurrency).format(exchange.amount)}',
                  ),
                  Text(
                    'Rate: ${exchange.rate} (${exchange.operator})',
                  ),
                  Text(
                    'Result: ${NumberFormat.currency(symbol: exchange.toCurrency).format(exchange.resultAmount)}',
                  ),
                  if (exchange.profitLoss != 0)
                    Text(
                      'Profit/Loss: ${NumberFormat.currency(symbol: exchange.toCurrency).format(exchange.profitLoss)}',
                      style: TextStyle(
                        color: exchange.profitLoss >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    formatLocalizedDateTime(context, exchange.date),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit(exchange);
                  } else if (value == 'delete') {
                    widget.onDelete(exchange);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
