import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:g9capstoneiotapp/Logic/GeoLocation/interpolation.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/chartview.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:latlong2/latlong.dart';

class HeatMapScreen extends StatefulWidget {
  final List<LocationInfo> locationList;
  final String mapName;

  const HeatMapScreen({required this.locationList, required this.mapName});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  late MapController _mapController;
  List<Marker> markers = [];
  List<LatLng> routePoints = [];
  List<Polygon> lakeBoundary = [];
  double averageDepth = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _processData();
  }

  void _processData() {
    if (widget.locationList.isEmpty) return;

    double totalDepth = widget.locationList.fold(0, (sum, loc) => sum + loc.distance.toDouble());
    averageDepth = totalDepth / widget.locationList.length;

    setState(() {
      routePoints = generateRoutePoints(widget.locationList);
      markers = _generateMarkers();
      lakeBoundary = _generateLakeBoundary();
    });
  }

  List<LatLng> generateRoutePoints(List<LocationInfo> locationList) {
    return locationList
        .where((loc) => loc.distance > averageDepth) // Filter points
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
  }


  List<Marker> _generateMarkers() {
    List<Marker> markerList = [];
    for (int i = 0; i < widget.locationList.length; i++) {
      LatLng point = LatLng(widget.locationList[i].latitude, widget.locationList[i].longitude);
      Color markerColor;
      if (i == 0) {
        markerColor = Colors.blue; // Start point
      } else if (i == widget.locationList.length - 1) {
        markerColor = Colors.purple; // End point
      } else {
        markerColor = widget.locationList[i].distance < averageDepth ? Colors.red : Colors.green;
      }

      markerList.add(
        Marker(
          point: point,
          width: 40,
          height: 60, // Adjusted height for text
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: markerColor, size: 40),
              Flexible(
                child: Text(
                  '${widget.locationList[i].distance.toStringAsFixed(2)} m', // Depth text
                  style: TextStyle(
                    fontSize: 10, // Adjust font size to avoid overflow
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
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
        color: Colors.blue.withOpacity(0.4), // Water fill effect
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
                MaterialPageRoute(builder: (context) => ChartsScreen(locationList: widget.locationList)),
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
                initialCenter: routePoints.isNotEmpty ? routePoints.first : LatLng(37.7749, -122.4194), // Default center
                initialZoom: routePoints.isNotEmpty ? 12 : 2, // Default zoom
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
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.orange,
                    )
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}