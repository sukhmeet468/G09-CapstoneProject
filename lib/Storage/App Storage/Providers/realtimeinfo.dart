import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

List<LocationInfo> _locationList = [];
String _heartbeatValue = "";
// ignore: unused_element
String _previousHeartbeatValue = ""; // Store previous heartbeat value

class LocationData with ChangeNotifier {
  // Getter to get the location list
  List<LocationInfo> get locationList => _locationList;

  // Add a new location to the list
  void addLocation(LocationInfo locationInfo) {
    _locationList.add(locationInfo);
    safePrint("Location added: $locationList");
    notifyListeners();  // Notify listeners to rebuild UI
  }

  // Getter for heartbeat value
  String get heartbeatValue => _heartbeatValue;

  // Setter for heartbeat value
  set setHeartbeatValue(String value) {
    _heartbeatValue = value;  // Set the new value
    notifyListeners();
  }
}
