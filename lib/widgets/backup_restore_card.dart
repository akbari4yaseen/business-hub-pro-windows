import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BackupRestoreCard extends StatelessWidget {
  const BackupRestoreCard({Key? key}) : super(key: key);

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.exportCanceledNoDirectory)),
        );
        return;
      }
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'BusinessHub__backup_${timestamp}.db';

      String backupPath = join(selectedDirectory, fileName);
      bool result = await DatabaseHelper().exportDatabase(backupPath);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .databaseExportedSuccessfully(backupPath))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .databaseFileNotFoundOrExportFailed)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .errorExportingDatabase(e.toString()))),
      );
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.restoreCanceledNoFile)),
        );
        return;
      }
      String backupPath = result.files.single.path!;
      bool resultRestore = await DatabaseHelper().importDatabase(backupPath);
      if (resultRestore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.databaseRestoredSuccessfully)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.restoreFailedFileNotFound)),
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
                Text(AppLocalizations.of(context)!.backupRestoreTitle,
                    style:
                        const TextStyle(fontSize: 18, fontFamily: "IRANSans")),
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
