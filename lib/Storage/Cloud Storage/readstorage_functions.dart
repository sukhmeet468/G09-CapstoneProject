import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:g9capstoneiotapp/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
        String filename = item.path;
        final downloadResult = await Amplify.Storage.downloadData(
          path: StoragePath.fromString(filename), // Path for the specific file
        ).result;
        // Decode file content as a JSON object
        final fileData = utf8.decode(downloadResult.bytes);
        final jsonData = jsonDecode(fileData);
        // Assuming jsonData is a List<dynamic>, so we need to map each item to a LocationInfo object
        if (jsonData is List) {
          List<LocationInfo> locationList = [];
          for (var jsonObject in jsonData) {
            try {
              // Safely extract values from jsonObject with default values or checks
              String timestamp = jsonObject['timestamp'] ?? "Unknown Timestamp";
              double distance = (jsonObject['distance'] ?? 0.0).toDouble();
              int confidence = (jsonObject['confidence'] ?? 0).toInt();
              double latitude = (jsonObject['latitude'] ?? 0.0).toDouble();
              double longitude = (jsonObject['longitude'] ?? 0.0).toDouble();
              double accuracy = (jsonObject['accuracy'] ?? 0.0).toDouble();
              // Create a LocationInfo object
              LocationInfo location = LocationInfo(
                timestamp: timestamp,
                distance: distance,
                confidence: confidence,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
              );
              locationList.add(location);  // Add to the list
              safePrint(locationList);
            } catch (e) {
              safePrint('Error parsing location data: $e');
            }
          }
          // Now, we can safely add the location list to the provider
          LocationMapProvider locationMapProvider = Provider.of<LocationMapProvider>(
            navigatorKeyhome.currentContext!,
            listen: false,
          );
          locationMapProvider.addLocationList(filename.split("/")[2], locationList);
        } else {
          safePrint('Expected a List but got something else: $jsonData');
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