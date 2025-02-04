import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Storage/Classes/routingclasses.dart';

int? findClosest(List<double> arr, double target) {
  // Special case: if the array is empty, return null
  if (arr.isEmpty) {
    return null;
  }

  // Use binary search to find the closest position
  int pos = binarySearch(arr, target);

  // If the position is at the end of the array, return the index of the last element
  if (pos == arr.length) {
    return arr.length - 1;
  }

  // Compare the element at the found position and the one before it (if possible)
  if (pos > 0 && (arr[pos - 1] - target).abs() <= (arr[pos] - target).abs()) {
    return pos - 1;
  } else {
    return pos;
  }
}

int binarySearch(List<double> arr, double  target) {
  int left = 0, right = arr.length;

  while (left < right) {
    int mid = left + (right - left) ~/ 2;

    if (arr[mid] < target) {
      left = mid + 1;
    } else {
      right = mid;
    }
  }

  return left;
}

// Utility function to get the next index, with bounds checking
List<int>? getNextIdx(List<int> currIdx, List<int> nextIdx, List<int> maxIdx, List<int> step) {
  nextIdx[0] = currIdx[0] + step[0];
  nextIdx[1] = currIdx[1] + step[1];

  if (nextIdx[0] >= maxIdx[0] || nextIdx[0] < 0 || nextIdx[1] >= maxIdx[1] || nextIdx[1] < 0) {
    return null;
  }
  return nextIdx;
}

// Function to update the current index and check if we have reached the end index
bool updateIdx(List<int> currIdx, List<int> nextIdx, List<int> endIdx, Compass compass) {
  List<int> step = [0, 0];

  if (nextIdx[0] < endIdx[0]) {
    step[0] = 1;
  } else if (nextIdx[0] > endIdx[0]) {
    step[0] = -1;
  }

  if (nextIdx[1] < endIdx[1]) {
    step[1] = 1;
  } else if (nextIdx[1] > endIdx[1]) {
    step[1] = -1;
  }

  currIdx.setAll(0, nextIdx);

  if (currIdx[0] == endIdx[0] && currIdx[1] == endIdx[1]) {
    return true;
  }
  compass.setHead(step);
  return false;
}

// Routing function to find the path from start to end
List<List<int>> routing(List<int> endIdx, List<List<double>> depthMap, int minDepth, List<List<int>> route, Compass compass, bool firstCollision, int maxRecursionDepth) {
  if (maxRecursionDepth <= 0) {
    return [];  // Prevent infinite recursion
  }

  List<List<int>> newRoute = List.from(route);
  bool foundEnd = false;
  Node movDir = compass.head!;
  List<int> maxIdx = [depthMap.length, depthMap[0].length];
  List<int> currIdx = List.from(route.last);
  List<int> nextIdx = [0, 0];
  int momentum = (depthMap.length * 0.1).toInt();
  int mntCnt = 0;

  while (!foundEnd) {
    nextIdx = getNextIdx(currIdx, nextIdx, maxIdx, movDir.data)!;

    if (depthMap[nextIdx[1]][nextIdx[0]] < minDepth) {
      foundEnd = updateIdx(currIdx, nextIdx, endIdx, compass);
      movDir = compass.head!;
      newRoute.add([currIdx[0], currIdx[1]]);
      if (mntCnt >= momentum) {
        firstCollision = true;
      } else {
        mntCnt++;
      }
    } else if (firstCollision) {
      List<List<int>> routeOne = routing(endIdx, depthMap, minDepth, List.from(route), Compass(rotation: "CW", data: movDir.data), false, maxRecursionDepth - 1);
      List<List<int>> routeTwo = routing(endIdx, depthMap, minDepth, List.from(route), Compass(rotation: "CCW", data: movDir.data), false, maxRecursionDepth - 1);

      if (routeOne.isEmpty && routeTwo.isEmpty) {
        return [];
      } else if (routeOne.isEmpty) {
        return routeTwo;
      } else if (routeTwo.isEmpty) {
        return routeOne;
      }

      if (routeOne.length <= routeTwo.length) {
        return routeOne;
      } else {
        return routeTwo;
      }
    } else {
      bool foundEscape = false;
      Node newDir = compass.head!.next!.next!;
      while (!foundEscape) {
        bool foundNext = false;
        newDir = newDir.prev!;
        while (!foundNext) {
          nextIdx = getNextIdx(currIdx, nextIdx, maxIdx, newDir.data)!;
          if (depthMap[nextIdx[1]][nextIdx[0]] >= minDepth) {
            newDir = newDir.next!;
          } else {
            foundNext = true;
          }
        }
        foundEnd = updateIdx(currIdx, nextIdx, endIdx, compass);
        if (movDir.name != compass.head!.name) {
          movDir = compass.head!;
          if (movDir.data[0] == -newDir.data[0] && movDir.data[1] == -newDir.data[1]) {
            newDir = compass.head!.next!.next!;
          } else {
            newDir = compass.head!.next!;
          }
        }
        if (foundEnd) foundEscape = true;
        newRoute.add([currIdx[0], currIdx[1]]);
      }
      mntCnt = 0;
    }
  }

  return newRoute;
}
List<List<int>> findRoute(List<double> startCoor, List<double> endCoor, List<double> lat, List<double> lon, List<List<double>> depthMap, int minDepth) {
  safePrint("Lat: $lat");
  safePrint("Long: $lon");
  safePrint("Start Lat: ${startCoor[0]}");
  safePrint("Start Long: ${startCoor[1]}");
  safePrint("End Lat: ${endCoor[0]}");
  safePrint("End Long: ${endCoor[1]}");

  int closeLatStart = _findClosestIndex(lat, startCoor[0]);
  int closeLonStart = _findClosestIndex(lon, startCoor[1]);
  int closeLatEnd = findClosest(lat, endCoor[0])!;
  int closeLonEnd = findClosest(lon, endCoor[1])!;

  if (closeLatStart == -1 || closeLonStart == -1 || closeLatEnd == -1 || closeLonEnd == -1) {
    // Handle the error gracefully or return early
    return [];
  }

  List<int> step = [0, 0];
  if (closeLatStart < closeLatEnd) {
    step[1] = 1;
  } else if (closeLatStart > closeLatEnd) {
    step[1] = -1;
  }

  if (closeLonStart < closeLonEnd) {
    step[0] = 1;
  } else if (closeLonStart > closeLonEnd) {
    step[0] = -1;
  }

  List<int> tmpStep = List.from(step);
  while (depthMap[closeLatStart][closeLonStart] >= minDepth) {
    if (closeLatStart == closeLatEnd) tmpStep[1] = 0;
    if (closeLonStart == closeLonEnd) tmpStep[0] = 0;
    closeLatStart += tmpStep[1];
    closeLonStart += tmpStep[0];
  }

  tmpStep = List.from(step);
  while (depthMap[closeLatEnd][closeLonEnd] >= minDepth) {
    if (closeLatStart == closeLatEnd) tmpStep[1] = 0;
    if (closeLonStart == closeLonEnd) tmpStep[0] = 0;
    closeLatEnd -= tmpStep[1];
    closeLonEnd -= tmpStep[0];
  }

  safePrint("Start Coor: (${lat[closeLatStart]}, ${lon[closeLatStart]}) $closeLonStart $closeLatStart");
  safePrint("End Coor: (${lat[closeLatEnd]}, ${lon[closeLatEnd]}) $closeLonEnd $closeLatEnd");

  List<int> endIdx = [closeLonEnd, closeLatEnd];
  List<List<int>> route = [[closeLonStart, closeLatStart]];

  route = routing(endIdx, depthMap, minDepth, route, Compass(data: step), true, 5);

  return route;
}

int _findClosestIndex(List<double> arr, double target) {
  int closestIdx = 0;
  double closestDist = (arr[0] - target).abs();
  for (int i = 1; i < arr.length; i++) {
    double dist = (arr[i] - target).abs();
    if (dist < closestDist) {
      closestDist = dist;
      closestIdx = i;
    }
  }
  return closestIdx;
}
