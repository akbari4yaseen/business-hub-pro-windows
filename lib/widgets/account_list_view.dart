import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'account_tile.dart';

class AccountListView extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isActive;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
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
    final loc = AppLocalizations.of(context)!;
    // total items = accounts + (loading/no-more) tile when needed
    final totalItems = accounts.length + ((hasMore || isLoadingMore) ? 1 : 0);

    // show empty state if nothing yet and not loading
    if (accounts.isEmpty && !isLoadingMore) {
      return Center(
        child: Text(loc.noAccountsAvailable),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 50),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (index < accounts.length) {
            final account = accounts[index];
            return AccountTile(
              account: account,
              isActive: isActive,
              onActionSelected: (action) =>
                  onActionSelected(action, account, isActive),
            );
          }
          // Load more / No more tile
          return _LoadingTile(
            isLoading: isLoadingMore,
            hasMore: hasMore,
            onLoadMore: onLoadMore,
            noMoreText: loc.noMoreAccounts,
          );
        },
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String noMoreText;

  const _LoadingTile({
    Key? key,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.noMoreText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If there's more to load but not currently loading, trigger automatically
    if (hasMore && !isLoading) {
      // schedule loadMore at end of frame to avoid modifying list during build
      WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _LoadingIndicator(),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorWidgetOfExactType<_LoadingTile>()!;
    if (state.isLoading) {
      return const CircularProgressIndicator();
    } else {
      return Text(state.noMoreText);
    }
  }
}
