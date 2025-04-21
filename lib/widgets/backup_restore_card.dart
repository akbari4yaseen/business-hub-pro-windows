import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
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

class BackupRestoreCard extends StatelessWidget {
  const BackupRestoreCard({Key? key}) : super(key: key);

  Future<void> _backupDatabase(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorExportingDatabase(e.toString()))),
      );
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorRestoringDatabase(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, size: 30, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  loc.backupRestoreTitle,
                  style: const TextStyle(fontSize: 18, fontFamily: 'IRANSans'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _backupDatabase(context),
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(loc.backup),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _restoreDatabase(context),
                    icon: const Icon(Icons.restore_outlined),
                    label: Text(loc.restore),
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
