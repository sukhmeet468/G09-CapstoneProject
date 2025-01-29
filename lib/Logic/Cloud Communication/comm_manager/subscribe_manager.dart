import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';
import 'package:g9capstoneiotapp/Logic/Notifications/local_notifications.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

Future<void> subMQTTTopics() async {
  //subscribe to all the Topics for all stations
  String prefixTopic = "g9capstone/#"; 
  subscribeToTopic(clientLocal, prefixTopic);
}

Future<void> handleReadValuesResponse(String msg) async {
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
  await showNotification();
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