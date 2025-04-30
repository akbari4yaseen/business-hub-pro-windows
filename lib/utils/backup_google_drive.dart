import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../database/database_helper.dart';

import 'package:intl/intl.dart';

/// Uploads the local DB file to the user's Google Drive.
Future<bool> backupToGoogleDrive() async {
  try {
    final dbPath = await DatabaseHelper().getDatabasePath();
    final file = File(dbPath);

    if (!file.existsSync()) return false;

    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
      serverClientId:
          '671765261723-1oaflrjjjd9m80deqnuv3uggl2qdrvo9.apps.googleusercontent.com',
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      return false;
    }

    final authHeaders = await account.authHeaders;
    final authClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authClient);

    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File()
      ..name =
          'BusinessHub_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db'
      ..parents = []; // root

    await driveApi.files.create(driveFile, uploadMedia: media);

    return true;
  } catch (e) {
    return false;
  }
}

/// HTTP client that injects Google Sign-In auth headers.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }
}
