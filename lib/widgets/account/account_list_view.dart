import 'package:flutter/material.dart';

import 'account_table.dart';

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
    if (hasMore && !isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: AccountTable(
        accounts: accounts,
        isActive: isActive,
        isLoadingMore: isLoadingMore,
        hasMore: hasMore,
        scrollController: scrollController,
        onActionSelected: onActionSelected,
      ),
    );
  }
}
