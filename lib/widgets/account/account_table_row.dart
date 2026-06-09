import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';

import '../../themes/app_theme.dart';
import '../../utils/account_share_helper.dart';
import '../../utils/account_types.dart';
import '../../utils/utilities.dart';

class AccountTableRow extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool isActive;
  final void Function(String) onActionSelected;

  static final NumberFormat _amountFormatter = NumberFormat('#,###.###');

  const AccountTableRow({
    Key? key,
    required this.account,
    required this.isActive,
    required this.onActionSelected,
  }) : super(key: key);

  String _displayName(BuildContext context) {
    final id = account['id'] as int? ?? 0;
    if (id <= 10) {
      return getLocalizedSystemAccountName(context, account['name']);
    }
    return account['name'] as String? ?? '';
  }

  Color _iconColor(String? type) {
    if (!isActive) return Colors.grey;
    return getAccountTypeColors[type] ?? AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accountType = account['account_type'] as String?;
    final balances = (account['balances'] as Map<String, dynamic>?) ?? {};
    final id = account['id'] as int? ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Name
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      _iconColor(accountType).withValues(alpha: 0.12),
                  child: Icon(
                    isActive
                        ? Icons.account_circle
                        : Icons.no_accounts_outlined,
                    size: 22,
                    color: _iconColor(accountType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(context),
                        style: const TextStyle(
                          fontFamily: 'VazirBold',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountType != null
                            ? '#$id · ${getLocalizedAccountType(context, accountType)}'
                            : '#$id',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: accountType != null
                              ? _iconColor(accountType)
                              : Colors.grey[500],
                          fontWeight: accountType != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Phone
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              account['phone'] != null ? '\u200E${account['phone']}' : '—',
              style: TextStyle(
                fontSize: 13,
                color: account['phone'] != null
                    ? Colors.grey[800]
                    : Colors.grey[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Address
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              account['address'] as String? ?? '—',
              style: TextStyle(
                fontSize: 13,
                color: account['address'] != null
                    ? Colors.grey[700]
                    : Colors.grey[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Balances
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _BalanceColumn(
              balances: balances,
              formatter: _amountFormatter,
            ),
          ),
        ),
        // Actions
        SizedBox(
          width: 48,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: loc.actions,
              padding: EdgeInsets.zero,
              onSelected: (value) async {
                if (value == 'copy_balance') {
                  final message = await buildShareMessage(context, account);
                  if (message.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.balanceCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } else {
                  onActionSelected(value);
                }
              },
              itemBuilder: (_) => _buildMenuItems(context),
            ),
          ),
        ),
      ],
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final id = account['id'] as int? ?? 0;
    final items = <PopupMenuItem<String>>[];

    if (isActive) {
      items.add(_menuItem('transactions', Icons.receipt_long_outlined,
          loc?.transactions ?? ''));
      if (id > 10) {
        items.add(_menuItem(
            'edit', FontAwesomeIcons.userPen, loc?.editAccount ?? ''));
        items.add(_menuItem('deactivate', FontAwesomeIcons.userSlash,
            loc?.deactivateAccount ?? ''));
      }
    } else if (id > 10) {
      items.add(_menuItem('reactivate', FontAwesomeIcons.userCheck,
          loc?.reactivateAccount ?? ''));
    }

    if (id > 10) {
      items.add(_menuItem(
          'delete', FontAwesomeIcons.trash, loc?.deleteAccount ?? ''));
    }

    items.add(_menuItem(
        'share', FontAwesomeIcons.shareNodes, loc?.shareBalance ?? ''));
    items.add(_menuItem(
        'whatsapp', FontAwesomeIcons.whatsapp, loc?.sendBalance ?? ''));
    items.add(_menuItem(
        'copy_balance', FontAwesomeIcons.copy, loc?.copyBalance ?? ''));

    return items;
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          FaIcon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  final Map<String, dynamic> balances;
  final NumberFormat formatter;

  const _BalanceColumn({
    required this.balances,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final entries = balances.entries.toList(growable: false);
    if (entries.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: Colors.grey[400], fontSize: 13),
      );
    }

    final visible = entries.take(3).toList();
    final remaining = entries.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((e) {
          final bal = e.value['summary']?['balance'] as double? ?? 0.0;
          final cur = e.value['currency'] as String? ?? '';
          return Text(
            '\u200E${formatter.format(bal)} $cur',
            style: TextStyle(
              color: bal >= 0 ? Colors.green[700] : Colors.red[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          );
        }),
        if (remaining > 0)
          Text(
            '+$remaining',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
