import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

/// HTTP client that injects Google Sign-In auth headers.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) =>
      _inner.send(req..headers.addAll(_headers));
}

/// Encapsulates all Drive backup logic.
class DriveBackupService {
  static const _folderName = 'BusinessHub';
  static const _prefsFolderIdKey = 'drive_businesshub_folder_id';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
    serverClientId:
        '671765261723-1oaflrjjjd9m80deqnuv3uggl2qdrvo9.apps.googleusercontent.com',
  );

  drive.DriveApi? _driveApi;

  /// Ensure we're signed in and have a Drive API client.
  Future<drive.DriveApi> _ensureDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in aborted');

    final headers = await account.authHeaders;
    _driveApi = drive.DriveApi(GoogleAuthClient(headers));
    return _driveApi!;
  }

  /// Get the folder ID from prefs, or look it up / create it on Drive.
  Future<String> _getBusinessHubFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsFolderIdKey);
    if (cached != null) return cached;

    final driveApi = await _ensureDriveApi();

    // 1) Look for an existing folder
    final result = await driveApi.files.list(
      q:
          "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
      pageSize: 1,
      $fields: 'files(id)',
    );

    String folderId;
    if (result.files != null && result.files!.isNotEmpty) {
      folderId = result.files!.first.id!;
    } else {
      // 2) Not found → create it
      final folderMeta = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await driveApi.files.create(folderMeta);
      folderId = created.id!;
    }

    await prefs.setString(_prefsFolderIdKey, folderId);
    return folderId;
  }

  /// Main entry: uploads the local DB into BusinessHub/
  Future<bool> backupDatabase() async {
    try {
      final dbPath = await DatabaseHelper().getDatabasePath();
      final file = File(dbPath);
      if (!await file.exists()) return false;

      final driveApi = await _ensureDriveApi();
      final folderId = await _getBusinessHubFolderId();

      final length = await file.length();
      final media = drive.Media(file.openRead(), length);

      final backupName =
          'BusinessHub_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
      final meta = drive.File()
        ..name = backupName
        ..parents = [folderId];

      await driveApi.files.create(
        meta,
        uploadMedia: media,
        // resumable uploads are used automatically for larger files
      );

      return true;
    } catch (e, st) {
      // you may wish to log `st` somewhere
      print('Backup error: $e');
      return false;
    }
  }
}
