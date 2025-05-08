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
    // Show empty state if there are no accounts and not loading more
    if (accounts.isEmpty && !isLoadingMore) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: Center(
          child: Text(AppLocalizations.of(context)!.noAccountsAvailable),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 50),
        itemCount: accounts.length + (hasMore || isLoadingMore ? 1 : 0),
        // Use a prototype item to lock in a fixed height without manual measurement
        prototypeItem: accounts.isNotEmpty
            ? AccountTile(
                account: accounts.first,
                isActive: isActive,
                onActionSelected: (_) {},
              )
            : null,
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
            // Load more indicator or end-of-list message
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
