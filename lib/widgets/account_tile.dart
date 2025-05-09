import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/utilities.dart';

class AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool isActive;
  final void Function(String) onActionSelected;

  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');
  // Predefined mapping of account types to colors
  static const Map<String, Color> _typeColors = {
    'system': Colors.pink,
    'customer': Colors.blue,
    'supplier': Colors.orange,
    'exchanger': Colors.teal,
    'bank': Colors.indigo,
    'income': Colors.green,
    'expense': Colors.red,
    'company': Colors.brown,
    'owner': Colors.lime,
  };

  const AccountTile({
    Key? key,
    required this.account,
    required this.isActive,
    required this.onActionSelected,
  }) : super(key: key);

  // Returns the appropriate icon color based on type and active state
  static Color _iconColor(String? type, bool isActive) {
    if (!isActive) return Colors.grey;
    return _typeColors[type] ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final balances = (account['balances'] as Map<String, dynamic>?) ?? {};
    final accountType = account['account_type'] as String?;
    final iconColor = _iconColor(accountType, isActive);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        onTap: () => onActionSelected('transactions'),
        leading: Icon(
          isActive ? Icons.account_circle : Icons.no_accounts_outlined,
          size: 40,
          color: iconColor,
        ),
        title: Text(
          (account['id'] as int? ?? 0) <= 10
              ? getLocalizedSystemAccountName(context, account['name'])
              : (account['name']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontFamily: "VazirBold"),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account['account_type'] != null)
              Text(
                getLocalizedAccountType(
                    context, account['account_type'] as String),
                style: const TextStyle(fontSize: 13),
              ),
            if (account['phone'] != null)
              Text(
                '\u200E${account['phone']}',
                style: const TextStyle(fontSize: 13),
              ),
            if (account['address'] != null)
              Text(
                account['address'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _BalanceScroller(
                balances: balances,
                formatter: _amountFormatter,
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: onActionSelected,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => _buildMenuItems(context),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final id = account['id'] as int? ?? 0;
    final items = <PopupMenuItem<String>>[];

    if (isActive) {
      items.add(_buildMenuItem(
          'transactions', FontAwesomeIcons.listUl, loc?.transactions ?? ''));
      if (id > 10) {
        items.add(_buildMenuItem(
            'edit', FontAwesomeIcons.userPen, loc?.editAccount ?? ''));
        items.add(_buildMenuItem('deactivate', FontAwesomeIcons.userSlash,
            loc?.deactivateAccount ?? ''));
      }
    } else if (id > 10) {
      items.add(_buildMenuItem('reactivate', FontAwesomeIcons.userCheck,
          loc?.reactivateAccount ?? ''));
    }

    if (id > 10) {
      items.add(_buildMenuItem(
          'delete', FontAwesomeIcons.trash, loc?.deleteAccount ?? ''));
    }

    items.add(_buildMenuItem(
        'share', FontAwesomeIcons.shareNodes, loc?.shareBalance ?? ''));

    items.add(_buildMenuItem(
        'whatsapp', FontAwesomeIcons.whatsapp, loc?.sendBalance ?? ''));

    if (account['phone'] != null && (account['phone'] as String).isNotEmpty) {
      items.add(_buildMenuItem('call', FontAwesomeIcons.phone, loc!.call));
    }
    return items;
  }

  PopupMenuItem<String> _buildMenuItem(
          String value, IconData icon, String text) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            FaIcon(icon, size: 16),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
}

class _BalanceScroller extends StatelessWidget {
  final Map<String, dynamic> balances;
  final NumberFormat formatter;

  const _BalanceScroller({
    Key? key,
    required this.balances,
    required this.formatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries = balances.entries.toList(growable: false);
    if (entries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: entries.map((e) {
            final bal = e.value['summary']?['balance'] as double? ?? 0.0;
            final cur = e.value['currency'] as String? ?? '';
            return Text(
              '\u200E${formatter.format(bal)} $cur',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: bal >= 0 ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
