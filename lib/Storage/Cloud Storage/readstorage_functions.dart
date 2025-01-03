import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:path_provider/path_provider.dart';

// key here is useremail/IoTData
Future<String> downloadToMemory(String key) async {
  try {
    final result = await Amplify.Storage.downloadData(
      path: StoragePath.fromString('public/$key.txt'),
      onProgress: (progress) {
        safePrint('Fraction completed: ${progress.fractionCompleted}');
      },
    ).result;

    String data = String.fromCharCodes(result.bytes);
    return data;
  } on StorageException catch (e) {
    safePrint(e.message);
    return "";
  }
}

Future<void> listAndReadMaps() async {
  try {
    // List all files in the specified path
    final listResult = await Amplify.Storage.list(
      path: const StoragePath.fromString('public/MappedRoutes'),
      options: const StorageListOptions(
        pluginOptions: S3ListPluginOptions.listAll(),
      ),
    ).result;
    safePrint('Listed items: ${listResult.items}');

    // Loop through the items and download each file's data
    for (final item in listResult.items) {
      try {
        final downloadResult = await Amplify.Storage.downloadData(
          path: StoragePath.fromString(item.path), // Path for the specific file
        ).result;
        // Decode file content as a JSON object
        final fileData = utf8.decode(downloadResult.bytes);
        final jsonData = jsonDecode(fileData);
        // Assuming the file contains a list of JSON objects
        if (jsonData is List) {
          for (final jsonObject in jsonData) {
            safePrint('JSON Object: $jsonObject');
          }
        } else {
          safePrint('Unexpected JSON format in file: $jsonData');
        }
      } catch (fileDownloadException) {
        safePrint('Error downloading file ${item.path}: $fileDownloadException');
      }
    }
  } on StorageException catch (e) {
    safePrint('Storage error: ${e.message}');
  }
}

Future<void> downloadFile(String s3FilePath, String localFileName) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final localFilePath = '${documentsDir.path}/$localFileName';
  try {
    final result = await Amplify.Storage.downloadFile(
      path: StoragePath.fromString('public/MappedRoutes/$s3FilePath'), // File path on S3
      localFile: AWSFile.fromPath(localFilePath), // Local file path with name
    ).result;

    safePrint('Downloaded file is located at: ${result.localFile.path}');
  } on StorageException catch (e) {
    safePrint(e.message);
  }
}
