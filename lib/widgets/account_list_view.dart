import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'account_tile.dart';

class AccountListView extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isActive;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;
  final void Function(String, Map<String, dynamic>, bool) onActionSelected;
  final ScrollController scrollController;

  const AccountListView({
    Key? key,
    required this.accounts,
    required this.isActive,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onActionSelected,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: accounts.isEmpty && !isLoadingMore
          ? Center(
              child: Text(AppLocalizations.of(context)!.noAccountsAvailable),
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 50),
              itemCount: accounts.length + (hasMore || isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < accounts.length) {
                  final account = accounts[index];
                  return AccountTile(
                    account: account,
                    isActive: isActive,
                    onActionSelected: (action) =>
                        onActionSelected(action, account, isActive),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)!.noMoreAccounts),
                    ),
                  );
                }
              },
            ),
    );
  }
}
