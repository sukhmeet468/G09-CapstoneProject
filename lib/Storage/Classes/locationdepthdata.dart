class LocationInfo {
  final String timestamp;
  final int distance;
  final int confidence;
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationInfo({
    required this.timestamp,
    required this.distance,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}
