import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      String? selectedFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Select location to save database backup',
        fileName: 'BusinessHub_backup.db',
      );
      if (selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export canceled. No file selected.')),
        );
        return;
      }

      String dbPath = join(await getDatabasesPath(), 'BusinessHub.db');
      File dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database file not found!')),
        );
        return;
      }

      await dbFile.copy(selectedFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database exported successfully to:\n$selectedFile')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting database: $e')),
      );
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import canceled. No file selected.')),
        );
        return;
      }

      String backupPath = result.files.single.path!;
      String dbPath = join(await getDatabasesPath(), 'BusinessHub.db');

      File backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup file not found!')),
        );
        return;
      }

      await backupFile.copy(dbPath);
      DatabaseHelper().database; // Reload the database

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database restored successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing database: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _exportDatabase(context),
              child: Text('Export Database'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _importDatabase(context),
              child: Text('Import Database'),
            ),
          ],
        ),
      ),
    );
  }
}
