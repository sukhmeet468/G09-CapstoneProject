import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart'; // Assuming this class exists

class HeatMapScreen extends StatelessWidget {
  final List<LocationInfo> locationList;
  final String mapName;

  const HeatMapScreen({required this.locationList, required this.mapName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mapName),
      ),
      body: ListView.builder(
        itemCount: locationList.length,
        itemBuilder: (context, index) {
          final location = locationList[index];
          return ListTile(
            title: Text('Location ${index + 1}'),
            subtitle: Text('Lat: ${location.latitude}, Lon: ${location.longitude}'),
            trailing: location.distance != null
                ? Text('Depth: ${location.distance}')
                : null, // Show depth if available
          );
        },
      ),
    );
  }
}
