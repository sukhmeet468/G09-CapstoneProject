import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart'; // Assuming this class exists

class HeatMapScreen extends StatefulWidget {
  final List<LocationInfo> locationList;
  final String mapName;

  const HeatMapScreen({required this.locationList, required this.mapName});

  @override
  State<HeatMapScreen> createState() => _BathymetricMapScreenState();
}

class _BathymetricMapScreenState extends State<HeatMapScreen> {
  final StreamController<void> _rebuildStream = StreamController.broadcast();
  List<WeightedLatLng> data = [];
  double averageDepth = 0;

  // Define gradients for bathymetric visualization using MaterialColors
  List<Map<double, MaterialColor>> bathymetricGradients = [
    {
      0.0: Colors.yellow, // Shallow areas
      0.25: Colors.green,
      0.5: Colors.green,
      0.75: Colors.red,
      1.0: Colors.red, // Deepest areas
    },
    {
      0.0: Colors.cyan,
      0.25: Colors.teal,
      0.5: Colors.green,
      0.75: Colors.lightGreen,
      1.0: Colors.lime,
    },
  ];

  var gradientIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBathymetricData();
  }

  @override
  void dispose() {
    _rebuildStream.close();
    super.dispose();
  }

  // Load bathymetric data from the location list
  void _loadBathymetricData() {
    if (widget.locationList.isEmpty) return;

    // Calculate the average depth
    double totalDepth = widget.locationList.fold(0, (sum, location) => sum + location.distance.toDouble());
    averageDepth = totalDepth / widget.locationList.length;

    setState(() {
      data = widget.locationList.map((location) {
        // Normalize depth values and classify as shallow or deep
        double depth = location.distance.toDouble();
        depth = depth < 0 ? depth.abs() : depth; // Convert negative depth to positive
        return WeightedLatLng(
          LatLng(location.latitude, location.longitude),
          depth,
        );
      }).toList();
    });
  }

  // Toggle between gradients
  void _toggleGradient() {
    setState(() {
      gradientIndex = (gradientIndex + 1) % bathymetricGradients.length;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _rebuildStream.add(null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Center map on the first location or default coordinates
    var initialLocation = widget.locationList.isNotEmpty
        ? widget.locationList[0]
        : LocationInfo(latitude: 57.8827, longitude: -6.0400, distance: 0);

    // FlutterMap widget to display the bathymetric map
    final map = FlutterMap(
      options: MapOptions(
        backgroundColor: Colors.blue,
        initialCenter: LatLng(initialLocation.latitude, initialLocation.longitude),
        initialZoom: 8.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          tileProvider: NetworkTileProvider(),
        ),
        if (data.isNotEmpty)
          HeatMapLayer(
            heatMapDataSource: InMemoryHeatMapDataSource(data: data),
            heatMapOptions: HeatMapOptions(
              gradient: bathymetricGradients[gradientIndex],
              minOpacity: 0.3, // Ensure bathymetry visualization is visible
              radius: 25.0, // Control spread of depth visualization
            ),
            reset: _rebuildStream.stream,
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mapName),
      ),
      body: Column(
        children: [
          Expanded(
            child: map,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    "Shallow (< $averageDepth)",
                    style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.water, color: Colors.lightBlue),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Deep (>= $averageDepth)",
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.water, color: Colors.deepPurple),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleGradient,
            child: Text('Switch Bathymetric Gradient'),
          ),
        ],
      ),
    );
  }
}