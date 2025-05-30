import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../database/settings_db.dart';
import '../../utils/backup_google_drive.dart';
import '../../utils/date_formatters.dart';

/// Requests appropriate permissions based on platform
Future<bool> ensureStoragePermission() async {
  if (Platform.isAndroid) {
    final perm = Permission.manageExternalStorage;
    if (await perm.isGranted) return true;
    final status = await perm.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  } else if (Platform.isWindows) {
    // Windows doesn't need explicit storage permissions
    return true;
  }
  return true;
}

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({Key? key}) : super(key: key);

  @override
  _DatabaseSettingsScreenState createState() => _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  bool _isOfflineBackingUp = false;
  bool _isOnlineBackingUp = false;
  bool _isRestoring = false;

  DateTime? _lastOnlineBackupDate;
  DateTime? _lastOfflineBackupDate;

  @override
  void initState() {
    super.initState();
    _fetchBackupInfo();
  }

  Future<void> _fetchBackupInfo() async {
    final onlineStr = await SettingsDBHelper().getSetting('lastOnlineBackup');
    final offlineStr = await SettingsDBHelper().getSetting('lastOfflineBackup');

    DateTime? onlineDate;
    if (onlineStr != null) {
      try {
        onlineDate = DateTime.parse(onlineStr);
      } catch (_) {/* ignore parse errors */}
    }

    DateTime? offlineDate;
    if (offlineStr != null) {
      try {
        offlineDate = DateTime.parse(offlineStr);
      } catch (_) {/* ignore parse errors */}
    }

    setState(() {
      _lastOnlineBackupDate = onlineDate;
      _lastOfflineBackupDate = offlineDate;
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

    String? backupPath;
    if (Platform.isWindows) {
      // For Windows, use the Documents folder
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(documentsDir.path, 'BusinessHubPro', 'Backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      backupPath = join(backupDir.path, 
        'BusinessHubPro_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db');
    } else {
      // For other platforms, use FilePicker
      final result = await FilePicker.platform.saveFile(
        dialogTitle: loc.selectBackupLocation,
        fileName: 'BusinessHubPro_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db',
      );
      backupPath = result;
    }

    if (backupPath == null) {
      _showSnackbar(context, loc.backupCanceledNoLocation);
      return;
    }

    setState(() => _isOfflineBackingUp = true);
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

  Future<void> _handleRestore(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.confirmRestore),
        content: Text(loc.restoreOverwriteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.restore),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!await ensureStoragePermission()) {
      _showSnackbar(context, loc.storagePermissionRequired);
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) {
      _showSnackbar(context, loc.restoreCanceledNoFile);
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final success = await DatabaseHelper().importFrom(path);
      _showSnackbar(
        context,
        success
            ? loc.databaseRestoredSuccessfully
            : loc.restoreFailedFileNotFound,
      );
      await _fetchBackupInfo();
    } catch (e) {
      _showSnackbar(context, loc.errorRestoringDatabase(e.toString()));
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final onlineStatus = _lastOnlineBackupDate != null
        ? formatLocalizedDateTime(context, _lastOnlineBackupDate.toString())
        : '';

    final offlineStatus = _lastOfflineBackupDate != null
        ? formatLocalizedDateTime(context, _lastOfflineBackupDate.toString())
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.databaseSettings),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBackupInfo,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildStatusCard(
                context,
                icon: Icons.cloud_done_rounded,
                title: loc.lastOnlineBackup,
                subtitle: onlineStatus,
              ),
              const SizedBox(height: 12),
              _buildStatusCard(
                context,
                icon: Icons.save_alt_rounded,
                title: loc.lastOfflineBackup,
                subtitle: offlineStatus,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_rounded),
                                SizedBox(width: 8),
                                Text(loc.backupOnline),
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
                                Text(loc.backupLocal)
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
                            Text(loc.restoreDatabase)
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
