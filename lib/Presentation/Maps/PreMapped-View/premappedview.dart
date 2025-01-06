import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/heatmapscreen.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:provider/provider.dart';

class PreMappedRoutesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Mapped Routes'),
      ),
      body: Consumer<LocationMapProvider>(
        builder: (context, locationMapProvider, child) {
          // Get all maps
          List<Map<String, dynamic>> locationMaps = locationMapProvider.getAllMaps();

          // If there are no maps, show a message
          if (locationMaps.isEmpty) {
            return const Center(child: Text('No maps available.'));
          }

          return ListView.builder(
            itemCount: locationMaps.length,
            itemBuilder: (context, index) {
              String mapName = locationMapProvider.getMapName(index);

              return GestureDetector(
                onTap: () {
                  // When a map is tapped, navigate to HeatMapScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HeatMapScreen(
                        locationList: locationMapProvider.getLocationList(index),
                        mapName: mapName,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent, // Background color of the button
                    borderRadius: BorderRadius.circular(12.0), // Rounded corners
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6.0,
                        offset: Offset(0, 2), // Shadow direction
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Colors.white), // Icon on the button
                      SizedBox(width: 10),
                      Flexible( // Add Flexible to avoid overflow
                        child: Text(
                          mapName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                          ),
                          maxLines: 1, // Limit the text to one line
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}