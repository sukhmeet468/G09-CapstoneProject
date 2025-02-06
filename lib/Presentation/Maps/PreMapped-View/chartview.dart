import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';
import 'package:g9capstoneiotapp/Logic/GeoLocation/interpolation.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

class ChartsScreen extends StatefulWidget {
  final List<LocationInfo> locationList;
  final List<dynamic> route;

  const ChartsScreen({required this.locationList, required this.route});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late String dataJson;
  late String routeJson;

  @override
  void initState() {
    super.initState();

    // Interpolate location data
    var interpolatedData = runInterpolation(widget.locationList);
    List<List<double>> xLongitude = interpolatedData['xLongitude'];
    List<List<double>> yLatitude = interpolatedData['yLatitude'];
    List<List<double>> zInterp = interpolatedData['zInterp'];

    // Prepare heatmap data
    List<List<dynamic>> heatmapData = [];
    for (int i = 0; i < xLongitude.length; i++) {
      for (int j = 0; j < xLongitude[i].length; j++) {
        heatmapData.add([xLongitude[i][j], yLatitude[i][j], zInterp[i][j]]);
      }
    }
    dataJson = jsonEncode(heatmapData);

    // Prepare route data for trendline
    List<List<dynamic>> routeData = widget.route
        .map((point) => [point[0], point[1]]) // Longitude, Latitude pairs
        .toList();
    routeJson = jsonEncode(routeData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Heatmap with Route")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Echarts(
          option: '''
            {
              tooltip: {},
              visualMap: {
                min: 0,
                max: 650,
                calculable: true,
                orient: 'horizontal',
                left: 'center',
                bottom: '15%'
              },
              xAxis: {
                type: 'category',
                name: 'Longitude'
              },
              yAxis: {
                type: 'category',
                name: 'Latitude'
              },
              series: [
                {
                  name: 'Depth',
                  type: 'heatmap',
                  data: $dataJson,
                  emphasis: {
                    itemStyle: {
                      borderColor: '#333',
                      borderWidth: 1
                    }
                  }
                },
                {
                  name: 'Route',
                  type: 'line',
                  data: $routeJson,
                  lineStyle: {
                    color: 'red',
                    width: 2
                  },
                  symbol: 'circle',
                  symbolSize: 6
                }
              ]
            }
          '''
        ),
      ),
    );
  }
}
