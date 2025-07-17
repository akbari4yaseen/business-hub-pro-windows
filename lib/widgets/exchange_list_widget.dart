import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'exchange/exchange_details_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/exchange.dart';
import '../database/exchange_db.dart';
import '../../utils/date_formatters.dart';

class ExchangeListWidget extends StatefulWidget {
  final Function(Exchange) onEdit;
  final Function(Exchange) onDelete;
  final List<Exchange> exchanges;
  final bool isLoading;
  final bool hasMore;
  final ScrollController scrollController;

  const ExchangeListWidget({
    Key? key,
    required this.onEdit,
    required this.onDelete,
    required this.exchanges,
    required this.isLoading,
    required this.hasMore,
    required this.scrollController,
  }) : super(key: key);

  @override
  _ExchangeListWidgetState createState() => _ExchangeListWidgetState();
}

class _ExchangeListWidgetState extends State<ExchangeListWidget> {
  static final NumberFormat _numberFormatter = NumberFormat('#,##0.##');

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

  void _showDetails(Exchange exchange) {
    showDialog(
      context: context,
      builder: (_) => ExchangeDetailsWidget(exchange: exchange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (widget.exchanges.isEmpty && !widget.isLoading) {
      return Center(child: Text(loc.noExchangesFound));
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.exchanges.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.exchanges.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final exchange = widget.exchanges[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: ListTile(
            onTap: () => _showDetails(exchange),
            title: Text(
              '${exchange.fromCurrency} ${loc.to} ${exchange.toCurrency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc.amount}: \u200E${_numberFormatter.format(exchange.amount)} ${exchange.fromCurrency}',
                ),
                Text(
                  '${loc.rate}: ${exchange.rate} (${exchange.operator})',
                ),
                Text(
                  '${loc.resultAmount}: \u200E${_numberFormatter.format(exchange.resultAmount)} ${exchange.toCurrency}',
                ),
                if (exchange.profitLoss != 0)
                  Text(
                    '${loc.profitLoss}: \u200E${_numberFormatter.format(exchange.profitLoss)} ${exchange.toCurrency}',
                    style: TextStyle(
                      color:
                          exchange.profitLoss >= 0 ? Colors.green : Colors.red,
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
                switch (value) {
                  case 'details':
                    _showDetails(exchange);
                    break;
                  case 'edit':
                    widget.onEdit(exchange);
                    break;
                  case 'delete':
                    widget.onDelete(exchange);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text(loc.details),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text(loc.edit),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text(loc.delete),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
