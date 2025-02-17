import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:g9capstoneiotapp/Logic/GeoLocation/interpolation.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/chartview.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/currusedmapinfo.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class HeatMapScreen extends StatefulWidget {
  final List<LocationInfo> locationList;
  final List<dynamic> route;
  final String mapName;

  const HeatMapScreen({required this.locationList, required this.mapName, required this.route});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  late MapController _mapController;
  List<Marker> markers = [];
  List<LatLng> routePoints = [];
  List<LatLng> safeRoutePoints = [];
  List<Polygon> blueLakeBoundary = [];
  List<Polygon> greenLakeBoundary = [];
  List<Polygon> redLakeBoundary = [];
  bool isMapActive = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _processData();
  }

  void _processData() {
    if (widget.locationList.isEmpty) return;

    setState(() {
      routePoints = generateRoutePoints(widget.locationList);
      markers = _generateNormalMarkers();
      
      // Separate markers into green, red, and blue categories
      List<LatLng> blueZoneRoute = generateRoutePointsForPrediction(["0", "1", "2", "3", "4"]);
      
      // Generate polygons for the boundaries of each zone
      blueLakeBoundary = _generateLakeBoundary(blueZoneRoute, Colors.blue);

      if (widget.route[0] != "NA") {
        safeRoutePoints = generateSafeRoute(widget.route);
      } else {
        safeRoutePoints = [];
      }
    });
  }

  List<LatLng> generateRoutePoints(List<LocationInfo> locationList) {
    return locationList.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();
  }

  List<LatLng> generateRoutePointsForPrediction(List<String> predictionValues) {
    return widget.locationList
        .where((loc) => predictionValues.contains(loc.prediction))
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
  }

  List<LatLng> generateSafeRoute(List<dynamic> route) {
    return route.map((point) => LatLng(point[0], point[1])).toList();
  }

  List<Marker> _generateNormalMarkers() {
    List<Marker> markerList = [];
    Color markerColor; // Declare the markerColor variable
    for (var location in widget.locationList) {
      LatLng point = LatLng(location.latitude, location.longitude);
      // Assign the color based on the prediction value
      if (location.prediction == "0" || location.prediction == "1") {
        markerColor = Colors.green;
      } else if (location.prediction == "2") {
        markerColor = Colors.yellow;
      } else if (location.prediction == "3") {
        markerColor = Colors.orange;
      } else {
        markerColor = Colors.red;
      }
      // Add the marker to the list
      markerList.add(
        Marker(
          point: point,
          width: 40,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: markerColor, size: 40),
              Flexible(
                child: Text(
                  '${location.distance.toStringAsFixed(2)} m',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markerList;
  }

  List<Polygon> _generateLakeBoundary(List<LatLng> routePoints, Color color) {
    if (routePoints.length < 3) return [];
    List<LatLng> boundaryPoints = computeConvexHull(routePoints);
    return [
      Polygon(
        points: boundaryPoints,
        color: color.withOpacity(0.4),  // Color for the specific boundary
        borderColor: color,
        borderStrokeWidth: 3,
      ),
    ];
  }

  List<Marker> _generatePatchesAroundMarkers() {
    List<Marker> patchMarkers = [];
    for (var location in widget.locationList) {
      Color markerColor;
      if (location.prediction == "0" || location.prediction == "1") {
        markerColor = Colors.green;
      } else if (location.prediction == "2") {
        markerColor = Colors.yellow;
      } else if (location.prediction == "3") {
        markerColor = Colors.orange;
      } else {
        markerColor = Colors.red;
      }
      
      // Generate small patches around the marker position
      LatLng point = LatLng(location.latitude, location.longitude);
      patchMarkers.add(
        Marker(
          point: point,
          width: 20, // Small size for the patch
          height: 20,
          child: Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: markerColor.withOpacity(0.5), // Slight transparency for patches
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return patchMarkers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Heat Map Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active,
                color: isMapActive ? Colors.green : Colors.red),
            onPressed: () {
              setState(() => isMapActive = true);
              Provider.of<SelectedMapProvider>(context, listen: false).selectMap(
                widget.mapName,
                widget.locationList,
                widget.route,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.stop,
                color: isMapActive ? Colors.black : Colors.grey),
            onPressed: isMapActive
                ? () {
                    setState(() => isMapActive = false);
                    Provider.of<SelectedMapProvider>(context, listen: false).clearSelection();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.show_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChartsScreen(locationList: widget.locationList, route: widget.route,)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: routePoints.isNotEmpty ? routePoints.first : LatLng(37.7749, -122.4194),
                initialZoom: routePoints.isNotEmpty ? 12 : 2,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  tileProvider: NetworkTileProvider(),
                ),
                // Add Blue Lake Boundary for all markers
                PolygonLayer(polygons: blueLakeBoundary),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: safeRoutePoints,
                      strokeWidth: 4.0,
                      color: Colors.transparent,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...markers,
                    ..._generatePatchesAroundMarkers(),
                    ...generateCylinderMarkers(safeRoutePoints)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<Marker> generateCylinderMarkers(List<LatLng> points) {
    return points.map((point) => Marker(
      point: point,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    )).toList();
  }
}
