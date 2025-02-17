import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

String? _selectedMapName;
List<LocationInfo> _selectedLocationList = [];
List<dynamic> _selectedRoute = [];

class SelectedMapProvider with ChangeNotifier {

  String? get selectedMapName => _selectedMapName;
  List<LocationInfo> get selectedLocationList => _selectedLocationList;
  List<dynamic> get selectedRoute => _selectedRoute;

  bool get hasSelectedMap => _selectedMapName != null;

  void selectMap(String mapName, List<LocationInfo> locations, List<dynamic> route) {
    _selectedMapName = mapName;
    _selectedLocationList = locations;
    _selectedRoute = route;
    notifyListeners();
    safePrint("Map Selected for use: $mapName where locationInfo is; $locations");
  }

  void clearSelection() {
    _selectedMapName = null;
    _selectedLocationList = [];
    _selectedRoute = [];
    notifyListeners();
    safePrint("Map cleared for using");
  }
}
