import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'exchange/exchange_details_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/exchange.dart';
import '../../utils/date_formatters.dart';
import '../themes/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (widget.exchanges.isEmpty && !widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.currency_exchange,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              loc.noExchangesFound,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'VazirBold',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Fixed Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          loc.date,
                          style: TextStyle(
                            fontFamily: 'VazirBold',
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHeaderCell(loc.fromAccount, Icons.account_balance, 2),
                _buildHeaderCell(loc.fromCurrency, Icons.currency_exchange, 1),
                _buildHeaderCell(loc.toCurrency, Icons.currency_exchange, 1),
                _buildHeaderCell(loc.amount, Icons.attach_money, 1),
                _buildHeaderCell(loc.resultAmount, Icons.calculate, 1),
                _buildHeaderCell(loc.actions, Icons.more_vert, 1),
              ],
            ),
          ),
        ),
        // Scrollable Data
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Rows
                  ...widget.exchanges.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exchange = entry.value;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: index.isEven 
                            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.03)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showDetails(exchange),
                        onLongPress: () => _showDetails(exchange),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            _buildDateCellFixed(DateTime.parse(exchange.date), context),
                            _buildAccountCell(exchange.fromAccountName ?? 'No Name (${exchange.fromAccountId})'),
                            _buildCurrencyCellSimple(exchange.fromCurrency),
                            _buildCurrencyCellSimple(exchange.toCurrency),
                            _buildAmountCell(exchange.amount, exchange.fromCurrency, context),
                            _buildAmountCell(exchange.resultAmount, exchange.toCurrency, context),
                            _buildActionsCell(exchange, loc),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  // Loading indicator for pagination
                  if (widget.hasMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, IconData icon, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'VazirBold',
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCellFixed(DateTime date, BuildContext context) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          formatLocalizedDateTime(context, date.toString()),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAccountCell(String accountName) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          accountName,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  Widget _buildCurrencyCellSimple(String currency) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          currency,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmountCell(double amount, String currency, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEnglish = locale == 'en';
    
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '\u200E${_numberFormatter.format(amount)} ${currency}',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: isEnglish ? TextAlign.start : TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Exchange exchange, AppLocalizations loc) {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 22),
        tooltip: loc.actions,
        padding: EdgeInsets.zero,
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
            default:
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                const Icon(Icons.info, size: 18),
                const SizedBox(width: 12),
                Text(loc.details),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(loc.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text(loc.delete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(Exchange exchange) {
    showDialog(
      context: context,
      builder: (_) => ExchangeDetailsWidget(exchange: exchange),
    );
  }
}
