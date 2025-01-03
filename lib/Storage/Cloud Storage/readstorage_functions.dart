import 'package:amplify_flutter/amplify_flutter.dart';

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
