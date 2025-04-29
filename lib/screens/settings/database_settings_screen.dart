import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Requests MANAGE_EXTERNAL_STORAGE permission on Android 11+.
Future<bool> ensureStoragePermission() async {
  if (Platform.isAndroid) {
    final perm = Permission.manageExternalStorage;
    if (await perm.isGranted) return true;
    final status = await perm.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }
  return true; // iOS and others don't need explicit storage perms
}

class DatabaseSettingsScreen extends StatefulWidget {
  final int lastOnlineBackupDays;
  final int lastOfflineBackupDays;
  final Future<void> Function() onOnlineBackup;
  final Future<void> Function() onOfflineBackup;
  final Future<void> Function() onRestore;
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
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Future<void> _handleOnlineBackup(BuildContext context) async {
    setState(() => _isOnlineBackingUp = true);
    try {
      await widget.onOnlineBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.onlineBackupSuccess)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.onlineBackupFailed)),
      );
    } finally {
      setState(() => _isOnlineBackingUp = false);
    }
  }

  Future<void> _handleOfflineBackup(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    // Ensure permission and selection before showing spinner
    if (!await ensureStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.storagePermissionRequired)),
      );
      return;
    }

    final selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.exportCanceledNoDirectory)),
      );
      return;
    }

    setState(() => _isOfflineBackingUp = true);
    final parentDir = dirname(selectedDir);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupName = 'BusinessHub__backup_${timestamp}.db';
    final backupPath = join(parentDir, backupName);

    try {
      final success = await DatabaseHelper().exportTo(backupPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? loc.databaseExportedSuccessfully(backupPath)
                : loc.databaseFileNotFoundOrExportFailed,
          ),
        ),
      );
      if (success) await widget.onOfflineBackup();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorExportingDatabase(e.toString()))),
      );
    } finally {
      setState(() => _isOfflineBackingUp = false);
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    // Confirm overwrite
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.confirmRestore),
        content: Text(loc.restoreOverwriteWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.restore)),
        ],
      ),
    );
    if (confirm != true) return;

    if (!await ensureStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.storagePermissionRequired)),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.restoreCanceledNoFile)),
      );
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final success = await DatabaseHelper().importFrom(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? loc.databaseRestoredSuccessfully
                : loc.restoreFailedFileNotFound,
          ),
        ),
      );
      if (success) await widget.onRestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorRestoringDatabase(e.toString()))),
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
                      onPressed: _isOnlineBackingUp
                          ? null
                          : () => _handleOnlineBackup(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isOnlineBackingUp
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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
                      onPressed: _isOfflineBackingUp
                          ? null
                          : () => _handleOfflineBackup(context),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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
                  onPressed:
                      _isRestoring ? null : () => _handleRestore(context),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
