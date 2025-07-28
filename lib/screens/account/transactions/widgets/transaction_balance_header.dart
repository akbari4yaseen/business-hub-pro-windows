import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../providers/theme_provider.dart';
import 'transaction_balance_card.dart';

class TransactionBalanceHeader extends StatelessWidget {
  final Map<String, dynamic> balances;
  final NumberFormat amountFormatter;

  const TransactionBalanceHeader({
    Key? key,
    required this.balances,
    required this.amountFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (balances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: SizedBox(
        height: 167,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: balances.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, idx) {
            final entry = balances.entries.elementAt(idx);
            return TransactionBalanceCard(
              entry: entry,
              amountFormatter: amountFormatter,
            );
          },
        ),
      ),
    );
  }
} 