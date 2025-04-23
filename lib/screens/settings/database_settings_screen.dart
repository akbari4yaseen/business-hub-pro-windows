import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  final int lastOnlineBackupDays;
  final int lastOfflineBackupDays;
  final VoidCallback onOnlineBackup;
  final VoidCallback onOfflineBackup;
  final VoidCallback onRestore;
  final Future<void> Function()? onRefresh;

  const DatabaseSettingsScreen({
    Key? key,
    required this.lastOnlineBackupDays,
    required this.lastOfflineBackupDays,
    required this.onOnlineBackup,
    required this.onOfflineBackup,
    required this.onRestore,
    this.onRefresh,
  }) : super(key: key);

  @override
  _DatabaseSettingsScreenState createState() => _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  bool _isOnlineBackingUp = false;
  bool _isOfflineBackingUp = false;
  bool _isRestoring = false;

  String _formatDate(int daysAgo) {
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  Future<void> _handleOnlineBackup() async {
    setState(() => _isOnlineBackingUp = true);
    try {
      await Future<void>.delayed(Duration.zero, widget.onOnlineBackup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.onlineBackupSuccess)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.onlineBackupFailed)),
      );
    } finally {
      setState(() => _isOnlineBackingUp = false);
    }
  }

  Future<void> _handleOfflineBackup() async {
    setState(() => _isOfflineBackingUp = true);
    try {
      await Future<void>.delayed(Duration.zero, widget.onOfflineBackup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.localBackupSuccess)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.localBackupFailed)),
      );
    } finally {
      setState(() => _isOfflineBackingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmRestore),
        content: Text(AppLocalizations.of(context)!.restoreOverwriteWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.restore)),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isRestoring = true);
    try {
      await Future<void>.delayed(Duration.zero, widget.onRestore);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.restoreSuccess)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.restoreFailed)),
      );
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.databaseSettings),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildStatusCard(
                context,
                icon: Icons.cloud_done_rounded,
                title: AppLocalizations.of(context)!.lastOnlineBackup,
                subtitle: _formatDate(widget.lastOnlineBackupDays),
              ),
              const SizedBox(height: 12),
              _buildStatusCard(
                context,
                icon: Icons.save_alt_rounded,
                title: AppLocalizations.of(context)!.lastOfflineBackup,
                subtitle: _formatDate(widget.lastOfflineBackupDays),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isOnlineBackingUp ? null : _handleOnlineBackup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isOnlineBackingUp
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_rounded),
                                SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.backupOnline)
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isOfflineBackingUp ? null : _handleOfflineBackup,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      child: _isOfflineBackingUp
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_for_offline_rounded),
                                SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.backupLocal)
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isRestoring ? null : _handleRestore,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    backgroundColor: theme.colorScheme.errorContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRestoring
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restore_rounded),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.restoreDatabase)
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 28, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
