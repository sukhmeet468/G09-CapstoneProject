import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

// List to store maps and their location lists
List<Map<String, dynamic>> locationMaps = [];

// This will hold multiple maps with their names and location lists
class LocationMapProvider with ChangeNotifier {
  
  // Method to get a location list from a specific map by its index
  List<LocationInfo> getLocationList(int index) {
    return locationMaps[index]['locationList'] ?? [];
  }

  // Method to get a map name by index
  String getMapName(int mapIndex) {
    return locationMaps[mapIndex]['mapName'] ?? "Unnamed Map";
  }

  // Method to add a new location list with a name for the map
  void addLocationList(String mapName, List<LocationInfo> newLocationList) {
    locationMaps.add({
      'mapName': mapName,
      'locationList': newLocationList,
    });
    notifyListeners();
  }

  // Method to get all maps (for displaying the map names)
  List<Map<String, dynamic>> getAllMaps() {
    return locationMaps;
  }

  // Method to set the entire list of maps
  void setLocationMaps(List<Map<String, dynamic>> newLocationMaps) {
    locationMaps = newLocationMaps;
    notifyListeners();
  }
}