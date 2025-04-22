import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/utilities.dart';

class AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool isActive;
  final void Function(String) onActionSelected;

  const AccountTile({
    Key? key,
    required this.account,
    required this.isActive,
    required this.onActionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balances = account['balances'] as Map<String, dynamic>;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        leading: Icon(
          isActive ? Icons.account_circle : Icons.no_accounts_outlined,
          size: 40,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(
          account['id'] <= 10
              ? getLocalizedSystemAccountName(context, account['name'])
              : account['name'],
          style: const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getLocalizedAccountType(context, account['account_type']),
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '\u200E${account['phone']}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${account['address']}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        trailing: _buildTrailing(context, balances),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, Map<String, dynamic> balances) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: balances.entries.map((e) {
            final bal = e.value['summary']['balance'] as double? ?? 0.0;
            return Text(
              '\u200E${NumberFormat('#,###.##').format(bal)} ${e.value['currency']}',
              style: TextStyle(
                color: bal >= 0 ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          onSelected: onActionSelected,
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => _buildMenuItems(context),
        ),
      ],
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final List<PopupMenuItem<String>> items = [];

    if (isActive) {
      items.add(_buildMenuItem(
          'transactions', FontAwesomeIcons.listUl, loc.transactions));
      if (account['id'] > 10) {
        items.add(
            _buildMenuItem('edit', FontAwesomeIcons.userPen, loc.editAccount));
        items.add(_buildMenuItem(
            'deactivate', FontAwesomeIcons.userSlash, loc.deactivateAccount));
      }
    } else if (account['id'] > 10) {
      items.add(_buildMenuItem(
          'reactivate', FontAwesomeIcons.userCheck, loc.reactivateAccount));
    }

    if (account['id'] > 10) {
      items.add(
          _buildMenuItem('delete', FontAwesomeIcons.trash, loc.deleteAccount));
    }

    items.add(
        _buildMenuItem('share', FontAwesomeIcons.shareNodes, loc.shareBalance));
    items.add(
        _buildMenuItem('whatsapp', FontAwesomeIcons.whatsapp, loc.sendBalance));

    return items;
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
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
}
