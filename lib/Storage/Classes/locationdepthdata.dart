class LocationInfo {
  final String timestamp;
  final int distance;
  final int confidence;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String outcome;

  LocationInfo({
    this.timestamp = "",
    required this.distance,
    this.confidence = 0,
    required this.latitude,
    required this.longitude,
    this.accuracy = 0.0,
    this.outcome = "",
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude'],
      longitude: json['longitude'],
      distance: json['distance'],
      confidence: json['confidence'],
      timestamp: json['timestamp'],
      accuracy: json['accuracy'],
      outcome: json['outcome']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'confidence': confidence,
      'timestamp': timestamp,
      'accuracy': accuracy,
      "outcome": outcome
    };
  }
}
