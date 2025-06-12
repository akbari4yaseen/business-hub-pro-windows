import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class DriveBackupService {
  static const _folderName = 'BusinessHubPro';
  static const _prefsFolderIdKey = 'drive_businesshub_folder_id';

  static const _clientId =
      '436609276204-ti9s0mr3k6f9s3oo9bi76d4ti7tohfuh.apps.googleusercontent.com'; // Web OAuth2 client ID
  static const _clientSecret =
      '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'; // Web OAuth2 client secret
  static final _scopes = [drive.DriveApi.driveFileScope];

  drive.DriveApi? _driveApi;

  /// Manually authorizes and creates Drive API client
  Future<drive.DriveApi> _ensureDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    var id = ClientId(_clientId, _clientSecret);

    await obtainAccessCredentialsViaUserConsent(id, _scopes, http.Client(),
        (url) {
      print('Please go to the following URL and grant access:');
      print('  => $url');
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }).then((credentials) {
      final client = authenticatedClient(http.Client(), credentials);
      _driveApi = drive.DriveApi(client);
    }).catchError((e) {
      print("Auth error: $e");
      throw Exception('Google OAuth2 failed');
    });

    return _driveApi!;
  }

  /// Get or create the BusinessHubPro folder
  Future<String> _getBusinessHubFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsFolderIdKey);
    if (cached != null) return cached;

    final driveApi = await _ensureDriveApi();
    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
      pageSize: 1,
      $fields: 'files(id)',
    );

    String folderId;
    if (result.files != null && result.files!.isNotEmpty) {
      folderId = result.files!.first.id!;
    } else {
      final folderMeta = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await driveApi.files.create(folderMeta);
      folderId = created.id!;
    }

    await prefs.setString(_prefsFolderIdKey, folderId);
    return folderId;
  }

  /// Uploads the DB file
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
          'BusinessHubPro_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
      final meta = drive.File()
        ..name = backupName
        ..parents = [folderId];

      await driveApi.files.create(meta, uploadMedia: media);
      return true;
    } catch (e) {
      print('Backup error: $e');
      return false;
    }
  }
}
