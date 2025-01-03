import 'package:amplify_flutter/amplify_flutter.dart';

// pathtostore is useremail/IoTData
// value is certs, keys
Future<void> uploadCertsDataAsFile(String pathtostore, String value) async {
  try {
    final result = await Amplify.Storage.uploadData(
      data: StorageDataPayload.string(
        value,
        contentType: 'text/plain',
      ),
      path: StoragePath.fromString('public/$pathtostore.txt'),
    ).result;
    safePrint('Uploaded data: ${result.uploadedItem.path}');
  } on StorageException catch (e) {
    safePrint(e.message);
  }
}