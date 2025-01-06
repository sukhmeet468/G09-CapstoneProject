import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:provider/provider.dart';

class RealTimeDepthScreen extends StatefulWidget {
  @override
  State<RealTimeDepthScreen> createState() => _RealTimeDepthScreenState();
}

class _RealTimeDepthScreenState extends State<RealTimeDepthScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update the UI every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.of to get the LocationData
    var locationData = Provider.of<LocationData>(context, listen: true);

    // List of LatLng points for the polyline
    List<LatLng> points = locationData.locationList
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Depth Monitoring'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Map:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Display the map
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points.isNotEmpty ? points.last : const LatLng(0, 0),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (points.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: locationData.locationList.map((location) {
                      return Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 120,
                        height: 120,
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Location Details'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Timestamp: ${location.timestamp}'),
                                    Text('Depth: ${location.distance} mm'),
                                    Text('Confidence: ${location.confidence}%'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Tooltip(
                            message: 'Depth: ${location.distance} mm\n'
                                'Confidence: ${location.confidence}%\n'
                                'Timestamp: ${location.timestamp}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4.0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${location.distance} mm',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}