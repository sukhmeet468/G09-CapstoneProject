import 'dart:math';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Logic/GeoLocation/routing.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> runInterpolation(List<LocationInfo> locationList) {
    var result = processInterpolation(locationList);
    return result; // Return the result
}

Map<String, dynamic> processInterpolation(List<LocationInfo> locationList) {
  double trim = 0.1;
  double mu = 0.03;

  safePrint("Original data List: $locationList");

  // Get coordinate values and z values
  List<List<double>> coorVals = getCoorVals(locationList);
  List<int> zVals = getZVals(locationList);

  // Print the initial coordinate values and z values
  safePrint("Coordinate Values: $coorVals");
  safePrint("Z Values: $zVals");

  var result1 = normSamples(coorVals);
  List<List<double>> coorValsNorm = result1[0];
  List<double> xyMin = result1[1];
  List<double> xyMax = result1[2];

  // Print normalized coordinate values, min, and max
  safePrint("Normalized Coordinate Values: $coorValsNorm");
  safePrint("XY Min: $xyMin");
  safePrint("XY Max: $xyMax");

  var result2 = meshgrid(trim);
  List<List<double>> xNorm = result2[0];
  List<List<double>> yNorm = result2[1];

  // Print the meshgrid result
  safePrint("Normalized X Grid: $xNorm");
  safePrint("Normalized Y Grid: $yNorm");

  // Compute the matrix of depth values using radial basis function interpolation
  List<List<double>> zInterp = rbfInterpolate(xNorm, yNorm, coorValsNorm, zVals, mu);

  // Print interpolated Z values
  safePrint("Interpolated Z Values: $zInterp");

  // Convert normalized X values back to longitude
  List<List<double>> xLongitude = xNorm.map((row) => 
    row.map((val) => (val * (xyMax[0] - xyMin[0])) + xyMin[0]).toList()
  ).toList();

  // Convert normalized Y values back to latitude
  List<List<double>> yLatitude = yNorm.map((row) => 
    row.map((val) => (val * (xyMax[1] - xyMin[1])) + xyMin[1]).toList()
  ).toList();

  // Print the final longitude and latitude values
  safePrint("Longitude Values: $xLongitude");
  safePrint("Latitude Values: $yLatitude");

  // Calculate min and max values for latitudes (y) and longitudes (x)
  double minLat = coorVals.map((e) => e[0]).reduce((a, b) => a < b ? a : b); // Min latitude
  double maxLat = coorVals.map((e) => e[0]).reduce((a, b) => a > b ? a : b); // Max latitude
  double minLon = coorVals.map((e) => e[1]).reduce((a, b) => a < b ? a : b); // Min longitude
  double maxLon = coorVals.map((e) => e[1]).reduce((a, b) => a > b ? a : b); // Max longitude

  // Generate x (longitude) and y (latitude) values
  List<double> xVals = List.generate(100, (i) => minLon + i * (maxLon - minLon) / 99);
  List<double> yVals = List.generate(100, (i) => minLat + i * (maxLat - minLat) / 99);

  safePrint("xVals: $xVals");
  safePrint("yVals: $yVals");

  // Get start and end coordinates
  List<double> startCoor = [(locationList.first.latitude), (locationList.first.longitude)];
  List<double> endCoor = [(locationList.last.latitude), (locationList.last.longitude)];

  safePrint("StartCoor: $startCoor");
  safePrint("EndCoor: $endCoor");

  // Calculate average depth from the locationList
  int averageDepth = (locationList.fold(0.0, (sum, loc) => sum + loc.distance) / locationList.length).toInt();

  safePrint("AvgDepth: $averageDepth");

  // run the routing algorithm
  List<List<int>> route = findRoute(startCoor, endCoor, xVals, yVals, zInterp, averageDepth);

  safePrint("Safe Route: $route");

  return {
    'xLongitude': xLongitude,
    'yLatitude': yLatitude,
    'zInterp': zInterp,
    'saferoute': route
  };
}

List<List<double>> getCoorVals(List<LocationInfo> locationList) {
  return locationList.map((loc) => [loc.longitude, loc.latitude]).toList();
}

List<int> getZVals(List<LocationInfo> locationList) {
  return locationList.map((loc) => loc.distance).toList(); // not accuracy depth
}

List<dynamic> normSamples(List<List<double>> coorVals) {
  double minX = coorVals.map((e) => e[0]).reduce(min);
  double minY = coorVals.map((e) => e[1]).reduce(min);
  double maxX = coorVals.map((e) => e[0]).reduce(max);
  double maxY = coorVals.map((e) => e[1]).reduce(max);

  List<List<double>> normalizedCoorVals = coorVals.map((e) => [
    (e[0] - minX) / (maxX - minX),
    (e[1] - minY) / (maxY - minY)
  ]).toList();

  return [normalizedCoorVals, [minX, minY], [maxX, maxY]];
}

List<List<List<double>>> meshgrid(double trim) {
  // Generate x_vals and y_vals similar to numpy linspace
  List<double> xVals = List.generate(100, (i) => trim + i * (1 - 2 * trim) / 99);
  List<double> yVals = List.generate(100, (i) => trim + i * (1 - 2 * trim) / 99);
  
  // Create X_norm (a grid of x_vals repeated for each y_val)
  List<List<double>> xNorm = [];
  for (var i = 0; i < yVals.length; i++) {
    xNorm.add(List<double>.from(xVals)); // Each row is a copy of xVals
  }
  // Create Y_norm (a grid of y_vals repeated for each x_val)
  List<List<double>> yNorm = [];
  for (var i = 0; i < xVals.length; i++) {
    yNorm.add(List<double>.from(yVals)); // Each row is a copy of yVals
  }

  // Return the X_norm and Y_norm
  return [xNorm, yNorm];
}

List<List<double>> rbfInterpolate(
  List<List<double>> X, List<List<double>> Y, 
  List<List<double>> coorVals, List<int> zVals, double mu
) {
  List<double> weights = calcWeights(coorVals, zVals, mu);
  return interpolate(X, Y, weights, coorVals, mu);
}

/// Computes weights using the Gram matrix method (Optimized)
List<double> calcWeights(List<List<double>> sampleCoor, List<int> z, double mu) {
  int n = sampleCoor.length;

  // Avoid large matrix multiplications
  List<List<double>> gramMatrix = List.generate(n, (i) =>
    List.generate(n, (j) {
      double dist = euclideanDist(sampleCoor[i], sampleCoor[j]);
      return exp(-dist / mu);
    })
  );

  // Compute weights = pseudo-inverse(Gram Matrix) * z
  List<List<double>> gramMatrixInv = matrixPseudoInverse(gramMatrix);
  return matrixVectorMultiply(gramMatrixInv, z);
}

/// Interpolates z-values over a grid (Optimized)
List<List<double>> interpolate(
  List<List<double>> X, List<List<double>> Y, List<double> w, 
  List<List<double>> sampleCoor, double mu
) {
  int m = X.length, p = X[0].length;

  List<List<double>> interpGrid = List.generate(m, (_) => List.filled(p, 0.0));

  for (int i = 0; i < m; i++) {
    for (int j = 0; j < p; j++) {
      double sum = 0;
      for (int k = 0; k < sampleCoor.length; k++) {
        double dist = euclideanDist([X[i][j], Y[i][j]], sampleCoor[k]);
        sum += w[k] * exp(-dist / mu);
      }
      interpGrid[i][j] = sum;
    }
  }

  return interpGrid;
}

/// Computes the Euclidean Distance (Memory Efficient)
double euclideanDist(List<double> A, List<double> B) {
  double sum = 0;
  for (int i = 0; i < A.length; i++) {
    sum += pow(A[i] - B[i], 2);
  }
  return sqrt(sum);
}

/// Computes the pseudo-inverse of a matrix (Placeholder for real implementation)
List<List<double>> matrixPseudoInverse(List<List<double>> matrix) {
  // Use numerical libraries like linalg for efficient implementation
  return matrix;
}

/// Multiplies a matrix by a vector
List<double> matrixVectorMultiply(List<List<double>> matrix, List<int> vector) {
  return List.generate(matrix.length, (i) =>
    List.generate(vector.length, (j) => matrix[i][j] * vector[j]).reduce((a, b) => a + b)
  );
}

/// Compute Convex Hull using Graham's Scan Algorithm
List<LatLng> computeConvexHull(List<LatLng> points) {
  if (points.length < 3) return points; // Convex Hull needs at least 3 points
  // Sort points by latitude (or longitude if equal)
  points.sort((a, b) => a.latitude == b.latitude
      ? a.longitude.compareTo(b.longitude)
      : a.latitude.compareTo(b.latitude));
  List<LatLng> hull = [];
  // Cross product to check left/right turn
  double cross(LatLng o, LatLng a, LatLng b) {
    return (a.latitude - o.latitude) * (b.longitude - o.longitude) -
           (a.longitude - o.longitude) * (b.latitude - o.latitude);
  }
  // Lower Hull
  for (LatLng p in points) {
    while (hull.length >= 2 &&
        cross(hull[hull.length - 2], hull.last, p) <= 0) {
      hull.removeLast();
    }
    hull.add(p);
  }
  // Upper Hull
  int t = hull.length + 1;
  for (int i = points.length - 2; i >= 0; i--) {
    while (hull.length >= t &&
        cross(hull[hull.length - 2], hull.last, points[i]) <= 0) {
      hull.removeLast();
    }
    hull.add(points[i]);
  }
  hull.removeLast(); // Remove duplicate point
  return hull;
}
