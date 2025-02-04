import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';
import 'package:g9capstoneiotapp/Logic/GeoLocation/interpolation.dart';
import 'package:g9capstoneiotapp/Storage/Classes/locationdepthdata.dart';

class ChartsScreen extends StatefulWidget {
  final List<LocationInfo> locationList;

  // Constructor to accept the locationList as an argument
  const ChartsScreen({required this.locationList});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late String dataJson;

  @override
  void initState() {
    super.initState();

    // Call the runInterpolation function to process the data
    var interpolatedData = runInterpolation(widget.locationList);

    // Prepare data for ECharts
    List<List<double>> xLongitude = interpolatedData['xLongitude'];
    List<List<double>> yLatitude = interpolatedData['yLatitude'];
    List<List<double>> zInterp = interpolatedData['zInterp'];

    // Flatten the matrix into a list of [longitude, latitude, zInterp] for heatmap
    List<List<dynamic>> heatmapData = [];
    for (int i = 0; i < xLongitude.length; i++) {
      for (int j = 0; j < xLongitude[i].length; j++) {
        heatmapData.add([xLongitude[i][j], yLatitude[i][j], zInterp[i][j]]);
      }
    }

    safePrint("Heat Map: ${heatmapData.length}");

    // Convert the heatmap data to JSON
    dataJson = jsonEncode(heatmapData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Heatmap")),
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
              series: [{
                name: 'Distance',
                type: 'heatmap',
                data: $dataJson,
              emphasis: {
                itemStyle: {
                  borderColor: '#333',
                  borderWidth: 1
                }
              }
            }]
          }
        '''
        ),
      ),
    );
  }
}
