import 'package:flutter/material.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';

import '../../themes/app_theme.dart';
import 'account_table_row.dart';

class AccountTable extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isActive;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final void Function(String, Map<String, dynamic>, bool) onActionSelected;

  const AccountTable({
    Key? key,
    required this.accounts,
    required this.isActive,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onActionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (accounts.isEmpty && !isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.people_outline : Icons.person_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              loc.noAccountsAvailable,
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
        _TableHeader(loc: loc),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
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
                  ...accounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final account = entry.value;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.03)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            onActionSelected('transactions', account, isActive),
                        borderRadius: BorderRadius.circular(8),
                        child: AccountTableRow(
                          account: account,
                          isActive: isActive,
                          onActionSelected: (action) =>
                              onActionSelected(action, account, isActive),
                        ),
                      ),
                    );
                  }),
                  if (hasMore || isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : Text(
                              loc.noMoreAccounts,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final AppLocalizations loc;

  const _TableHeader({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
            _headerCell(loc.name, Icons.person, 3),
            _headerCell(loc.phone, Icons.phone_outlined, 2),
            _headerCell(loc.address, Icons.location_on_outlined, 2),
            _headerCell(loc.balance, Icons.account_balance_wallet_outlined, 2),
            SizedBox(
              width: 48,
              child: Center(
                child: Tooltip(
                  message: loc.actions,
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, IconData icon, int flex) {
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
}
