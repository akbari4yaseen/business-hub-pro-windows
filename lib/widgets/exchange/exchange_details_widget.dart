import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/utilities.dart';
import '../../../models/exchange.dart';
import '../../../database/account_db.dart';

class ExchangeDetailsWidget extends StatefulWidget {
  final Exchange exchange;
  static final NumberFormat _numberFormatter = NumberFormat('#,###.##');

  const ExchangeDetailsWidget({Key? key, required this.exchange}) : super(key: key);

  @override
  State<ExchangeDetailsWidget> createState() => _ExchangeDetailsWidgetState();
}

class _ExchangeDetailsWidgetState extends State<ExchangeDetailsWidget> {
  final _accountDb = AccountDBHelper();
  String? _fromAccountName;
  String? _toAccountName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountNames();
  }

  Future<void> _loadAccountNames() async {
    try {
      final fromAccount = await _accountDb.getAccountById(widget.exchange.fromAccountId);
      final toAccount = await _accountDb.getAccountById(widget.exchange.toAccountId);
      
      if (mounted) {
        setState(() {
          _fromAccountName = fromAccount?['name'];
          _toAccountName = toAccount?['name'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account names: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.exchangeDetails,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Content
                  _detailItem(
                    loc.fromAccount,
                    _isLoading
                        ? 'Loading...'
                        : getLocalizedSystemAccountName(context, _fromAccountName ?? ''),
                  ),
                  _detailItem(
                    loc.toAccount,
                    _isLoading
                        ? 'Loading...'
                        : getLocalizedSystemAccountName(context, _toAccountName ?? ''),
                  ),
                  _detailItem(loc.fromCurrency, widget.exchange.fromCurrency),
                  _detailItem(loc.toCurrency, widget.exchange.toCurrency),
                  _detailItem(
                    loc.amount,
                    '\u200E${ExchangeDetailsWidget._numberFormatter.format(widget.exchange.amount)} ${widget.exchange.fromCurrency}',
                  ),
                  _detailItem(loc.rate, '${widget.exchange.rate} (${widget.exchange.operator})'),
                  _detailItem(
                    loc.resultAmount,
                    '\u200E${ExchangeDetailsWidget._numberFormatter.format(widget.exchange.resultAmount)} ${widget.exchange.toCurrency}',
                  ),
                  if (widget.exchange.expectedRate != null)
                    _detailItem(loc.expectedRateOptional, widget.exchange.expectedRate.toString()),
                  if (widget.exchange.profitLoss != 0)
                    _detailItem(
                      loc.profitLoss,
                      '\u200E${ExchangeDetailsWidget._numberFormatter.format(widget.exchange.profitLoss)} ${widget.exchange.toCurrency}',
                      valueColor: widget.exchange.profitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  if (widget.exchange.description != null && widget.exchange.description!.isNotEmpty)
                    _detailItem(loc.description, widget.exchange.description!),
                  _detailItem(loc.date, formatLocalizedDateTime(context, widget.exchange.date)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String title, String content, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
} 