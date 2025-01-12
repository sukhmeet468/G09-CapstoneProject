import 'dart:async';

import 'package:g9capstoneiotapp/Logic/GeoLocation/user_location.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:geolocator/geolocator.dart';

class HazardNotifier {
  final LocationMapProvider _locationMapProvider = LocationMapProvider();

  // Check hazards and trigger notification if necessary
  Future<void> checkHazards() async {
    // Get the user's current location
    Position userPosition = await getCurrentLocation();

    // Loop through all location maps and check the hazards
    for (var map in _locationMapProvider.getAllMaps()) {
      List<LocationInfo> locationList = map['locationList'];
      for (LocationInfo location in locationList) {
        // Only check if the location is marked as "notSafe"
        if (location.confidence > 0) {
          double distance = calculateDistance(userPosition.latitude, userPosition.longitude, location.latitude, location.longitude);
          if (distance <= 25.0) {
            // Send notification if hazard is within 25 meters
            // await _notificationService.showNotification(
            //   'Hazard Alert!',
            //   'A hazard is within 25 meters of your location!',
            // );
          }
        }
      }
    }
  }
}

void startHazardCheck() {
  Timer.periodic(Duration(minutes: 1), (timer) {
    HazardNotifier().checkHazards();
  });
}
