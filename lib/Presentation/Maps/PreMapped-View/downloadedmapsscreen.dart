import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/premappedview.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/heatmapscreen.dart';

class DownloadedMapsScreen extends StatefulWidget {
  @override
  State<DownloadedMapsScreen> createState() => _DownloadedMapsScreenState();
}

class _DownloadedMapsScreenState extends State<DownloadedMapsScreen> {
  List<Map<String, dynamic>> downloadedMaps = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedMaps();
  }

  Future<void> _loadDownloadedMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedMapsJson = prefs.getStringList('downloaded_maps') ?? [];

    setState(() {
      downloadedMaps = downloadedMapsJson
          .map((mapJson) => jsonDecode(mapJson) as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (context) => LocationData()),
                    ChangeNotifierProvider(create: (_) => LocationMapProvider()),
                  ],
                  child: PreMappedRoutesScreen(),
                ),
              ),
            );
          },
        ),
        title: const Text('Downloaded Maps'),
      ),
      body: downloadedMaps.isEmpty
          ? const Center(child: Text('No downloaded maps available.'))
          : ListView.builder(
              itemCount: downloadedMaps.length,
              itemBuilder: (context, index) {
                final mapData = downloadedMaps[index];
                final mapName = mapData['name'];
                final dynamicLocations = mapData['locations'] as List<dynamic>;
                final saferoute = mapData['saferoute'] as List<dynamic>;
                return GestureDetector(
                  onTap: () {
                    // Convert List<dynamic> to List<LocationInfo>
                    final locationList = dynamicLocations
                        .map((item) => LocationInfo.fromJson(item))
                        .toList();

                    // Navigate to HeatMapScreen with locationList
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HeatMapScreen(
                          locationList: locationList,
                          mapName: mapName,
                          route: saferoute,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: Colors.white),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            mapName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteMap(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteMap(int index) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      downloadedMaps.removeAt(index);
    });

    // Save updated list back to SharedPreferences
    final updatedMapsJson =
        downloadedMaps.map((map) => jsonEncode(map)).toList();
    await prefs.setStringList('downloaded_maps', updatedMapsJson);
  }
}