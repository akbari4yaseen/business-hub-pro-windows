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
    // On Android 11+, this covers all file access.
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return false;
  }
  // iOS and other platforms don't need this.
  return true;
}

class BackupRestoreCard extends StatelessWidget {
  const BackupRestoreCard({Key? key}) : super(key: key);

  Future<void> _backupDatabase(BuildContext context) async {
    // 1️⃣ Ensure we have storage permission
    final hasPermission = await ensureStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.storagePermissionRequired ??
                'Storage permission is required to back up.',
          ),
        ),
      );
      return;
    }

    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.exportCanceledNoDirectory,
            ),
          ),
        );
        return;
      }

      // Copy into parent directory (avoid duplicate folder)
      final parentDirPath = dirname(selectedDirectory);

      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'BusinessHub__backup_${timestamp}.db';
      final backupPath = join(parentDirPath, fileName);

      final success = await DatabaseHelper().exportDatabase(backupPath);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .databaseExportedSuccessfully(backupPath),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.databaseFileNotFoundOrExportFailed,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorExportingDatabase(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    // 1️⃣ Ensure we have storage permission (to read the selected file)
    final hasPermission = await ensureStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.storagePermissionRequired ??
                    'Storage permission is required to restore.')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.restoreCanceledNoFile)),
        );
        return;
      }
      final backupPath = result.files.single.path!;
      final success = await DatabaseHelper().importDatabase(backupPath);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.databaseRestoredSuccessfully),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.restoreFailedFileNotFound),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .errorRestoringDatabase(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  AppLocalizations.of(context)!.backupRestoreTitle,
                  style: const TextStyle(fontSize: 18, fontFamily: "IRANSans"),
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
                    label: Text(AppLocalizations.of(context)!.backup),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _restoreDatabase(context),
                    icon: const Icon(Icons.restore_outlined),
                    label: Text(AppLocalizations.of(context)!.restore),
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
