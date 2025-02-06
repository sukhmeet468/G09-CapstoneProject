import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:g9capstoneiotapp/Logic/GeoLocation/interpolation.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/chartview.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:latlong2/latlong.dart';

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
  List<Polygon> lakeBoundary = [];
  double minDepth = 0;
  double maxDepth = 0;

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
      int mostOccurringDepth = _findMostOccurringDepth();
      minDepth = mostOccurringDepth - 50;
      maxDepth = mostOccurringDepth + 50;
      markers = _generateMarkers();
      lakeBoundary = _generateLakeBoundary();
      if (widget.route[0] != "NA") {
        safeRoutePoints = generateSafeRoute(widget.route);
      } else {
        safeRoutePoints = [];
      }
    });
  }

  int _findMostOccurringDepth() {
    Map<int, int> depthCounts = {};
    for (var location in widget.locationList) {
      depthCounts[location.distance] = (depthCounts[location.distance] ?? 0) + 1;
    }
    return depthCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<LatLng> generateRoutePoints(List<LocationInfo> locationList) {
    return locationList.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();
  }

  List<LatLng> generateSafeRoute(List<dynamic> route) {
    return route.map((point) => LatLng(point[0], point[1])).toList();
  }

  List<Marker> _generateMarkers() {
    List<Marker> markerList = [];
    for (var location in widget.locationList) {
      LatLng point = LatLng(location.latitude, location.longitude);
      Color markerColor = (location.distance >= minDepth && location.distance <= maxDepth) ? Colors.green : Colors.red;

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

  List<Polygon> _generateLakeBoundary() {
    if (routePoints.length < 3) return [];
    List<LatLng> boundaryPoints = computeConvexHull(routePoints);
    return [
      Polygon(
        points: boundaryPoints,
        color: Colors.blue.withOpacity(0.4),
        borderColor: Colors.blue.shade900,
        borderStrokeWidth: 3,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Heat Map Screen"),
        actions: [
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
                PolygonLayer(polygons: lakeBoundary),
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
                    ...generateCylinderMarkers(safeRoutePoints),
                  ],
                )
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