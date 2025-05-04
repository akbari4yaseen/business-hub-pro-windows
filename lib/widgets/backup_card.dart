import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../../database/settings_db.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/backup_google_drive.dart';

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
  return true;
}

class BackupCard extends StatefulWidget {
  const BackupCard({Key? key}) : super(key: key);

  @override
  _BackupCardState createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _isOfflineBackingUp = false;
  bool _isOnlineBackingUp = false;

  int? _lastOnlineBackupDays;
  int? _lastOfflineBackupDays;

  @override
  void initState() {
    super.initState();
    _fetchBackupInfo();
  }

  Future<void> _fetchBackupInfo() async {
    final onlineStr = await SettingsDBHelper().getSetting('lastOnlineBackup');
    final offlineStr = await SettingsDBHelper().getSetting('lastOfflineBackup');

    int? onlineDays;
    int? offlineDays;

    if (onlineStr != null) {
      try {
        final onlineDate = DateTime.parse(onlineStr);
        onlineDays = DateTime.now().difference(onlineDate).inDays;
      } catch (_) {}
    }
    if (offlineStr != null) {
      try {
        final offlineDate = DateTime.parse(offlineStr);
        offlineDays = DateTime.now().difference(offlineDate).inDays;
      } catch (_) {}
    }

    setState(() {
      _lastOnlineBackupDays = onlineDays;
      _lastOfflineBackupDays = offlineDays;
    });
  }

  Future<void> _handleOnlineBackup(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isOnlineBackingUp = true);

    try {
      final success = await DriveBackupService().backupDatabase();

      if (success) {
        await SettingsDBHelper().saveSetting(
          'lastOnlineBackup',
          DateTime.now().toIso8601String(),
        );
        _showSnackbar(context, loc.onlineBackupSuccess);
      } else {
        _showSnackbar(context, loc.onlineBackupFailed);
      }
      await _fetchBackupInfo();
    } catch (_) {
      _showSnackbar(context, loc.onlineBackupFailed);
    } finally {
      setState(() => _isOnlineBackingUp = false);
    }
  }

  Future<void> _handleOfflineBackup(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    if (!await ensureStoragePermission()) {
      _showSnackbar(context, loc.storagePermissionRequired);
      return;
    }

    final selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir == null) {
      _showSnackbar(context, loc.exportCanceledNoDirectory);
      return;
    }

    setState(() => _isOfflineBackingUp = true);
    final parentDir = dirname(selectedDir);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupName = 'BusinessHub__backup_${timestamp}.db';
    final backupPath = join(parentDir, backupName);

    try {
      final success = await DatabaseHelper().exportTo(backupPath);
      if (success) {
        await SettingsDBHelper().saveSetting(
          'lastOfflineBackup',
          DateTime.now().toIso8601String(),
        );
      }
      _showSnackbar(
        context,
        success
            ? loc.databaseExportedSuccessfully(backupPath)
            : loc.databaseFileNotFoundOrExportFailed,
      );
      await _fetchBackupInfo();
    } catch (e) {
      _showSnackbar(context, loc.errorExportingDatabase(e.toString()));
    } finally {
      setState(() => _isOfflineBackingUp = false);
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final onlineStatus = _lastOnlineBackupDays != null
        ? loc.daysAgo(_lastOnlineBackupDays!)
        : '';
    final offlineStatus = _lastOfflineBackupDays != null
        ? loc.daysAgo(_lastOfflineBackupDays!)
        : '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.backup, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  loc.backupTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.backupCardFriendlyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Status rows
            Row(
              children: [
                Icon(Icons.cloud_done_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  loc.lastOnlineBackup + ': ' + onlineStatus,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.save_alt_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  loc.lastOfflineBackup + ': ' + offlineStatus,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 32),
            // Action buttons
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isOnlineBackingUp
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_rounded),
                              const SizedBox(width: 8),
                              Text(loc.online),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    child: _isOfflineBackingUp
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_for_offline_rounded),
                              const SizedBox(width: 8),
                              Text(loc.offline),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
