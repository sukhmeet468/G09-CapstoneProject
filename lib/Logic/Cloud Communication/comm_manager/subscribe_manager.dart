import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';
import 'package:g9capstoneiotapp/Logic/Notifications/local_notifications.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:path_provider/path_provider.dart';

Future<void> subMQTTTopics() async {
  //subscribe to all the Topics for all stations
  String prefixTopic = "g9capstone/#"; 
  subscribeToTopic(clientLocal, prefixTopic);
}

Future<void> handleReadValuesResponse(String msg) async {
  //-------------------------Get Current Time----------------------------//
  DateTime currentTime = (DateTime.now().toUtc());
  safePrint("Real Time Value Received: $msg at the Current Time: ${currentTime.millisecondsSinceEpoch}");

  //-------------------------Initializing Variables----------------------------//
  LocationData locationDataProvider = LocationData();

  //-------------------------Parse the Incoming Message------------------------//
  dynamic parsedMessage;
  try {
    parsedMessage = jsonDecode(msg);
  } catch (e) {
    safePrint("Error decoding JSON: $e");
    return;
  }

  //-------------------------Extract Values------------------------------------//
  String timestamp = parsedMessage['timestamp'] ?? '';
  int distance = (parsedMessage['distance'] ?? 0).toInt();
  int confidence = (parsedMessage['confidence'] ?? 0).toInt();
  double latitude = (parsedMessage['latitude'] ?? 0).toDouble();
  double longitude = (parsedMessage['longitude'] ?? 0).toDouble();
  double accuracy = (parsedMessage['accuracy'] ?? 0).toDouble();

  //----------------------Update the Provider----------------------------------//
  LocationInfo newLocation = LocationInfo(
    timestamp: timestamp,
    distance: distance,
    confidence: confidence,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
  );

  // update the provider
  locationDataProvider.addLocation(newLocation);
  safePrint("$distance-$timestamp-$confidence-$latitude-$longitude-$accuracy");

  //----------------------Write Log to Local File-----------------------------//
  await writeLogToFile(msg);

  await showNotification();
}

/// Writes a JSON log entry to a local file
Future<void> writeLogToFile(String message) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/log.txt');
    
    // Append the new message to the log file
    await file.writeAsString('$message\n', mode: FileMode.append);
    
    safePrint("Log written to file");
  } catch (e) {
    safePrint("Error writing to file: $e");
  }
}

Future<void> handleHeartbeatResponse(String msg) async {
  //-------------------------Initializing Variables----------------------------//
  LocationData locationDataProvider = LocationData();
  //-------------------------Parse the Incoming Message------------------------//
  dynamic parsedMessage;
  try {
    parsedMessage = jsonDecode(msg);
  } catch (e) {
    safePrint("Error decoding JSON: $e");
    return;
  }
  // update the provider
  locationDataProvider.setHeartbeatValue = parsedMessage['heartbeat'].toString();
  safePrint("$msg - heartbeat");
}