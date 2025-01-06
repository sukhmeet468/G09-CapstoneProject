import 'dart:async';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/fleetprovisionmanager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';
import 'package:g9capstoneiotapp/Presentation/Device%20Control/devicecontrol.dart';
import 'package:g9capstoneiotapp/Presentation/Home/customhearbeat.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/premappedview.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/RealTime-View/realtimedepthscreen.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/Cloud%20Storage/readstorage_functions.dart';
import 'package:g9capstoneiotapp/main.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAppConnected = false; // Simulate app connection status
  bool isPiOnline = false; // Simulate Pi connection status
  bool isConnecting = false; // Track connection state
  late Timer heartbeatTimer; // Declare the timer here
  String prevheartbeatValue = "";

  @override
  void initState() {
    super.initState();
    // Start checking heartbeat after the widget has been initialized
    startHeartbeatCheck();
  }

  void startHeartbeatCheck() {
    // Timer to check heartbeat every 1 minute
    heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      var locationdata = Provider.of<LocationData>(context, listen: false);
      safePrint("$prevheartbeatValue - ${locationdata.heartbeatValue}");
      if (prevheartbeatValue != locationdata.heartbeatValue) {
        prevheartbeatValue = locationdata.heartbeatValue;
        setState(() {
          isPiOnline = true;
        });
      } else {
        setState(() {
          isPiOnline = false;
        });
      }
    });
  }

  // Connect action for the Connect button
  Future<void> connectAction() async {
    setState(() {
      isConnecting = true; // Set connecting to true when starting connection
    });

    // Simulate the connection process
    await downloadCertificateAndKeys();
    // read the pre mapped routes
    await listAndReadMaps();

    // Check if client is connected
    if (clientLocal.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        isAppConnected = true;
      });
    } else {
      setState(() {
        isAppConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKeyhome,
      builder: Authenticator.builder(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Real-Time Depth and Location Display'),
          actions: [
            IconButton(
              onPressed: () async {
                await Amplify.Auth.signOut();
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wi-Fi State Bar
              _buildWifiStateBar(),
              const SizedBox(height: 16),
              // Connect Button
              ElevatedButton(
                onPressed: isConnecting ? null : connectAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: isConnecting ? Colors.grey : Colors.green, // Grey out if connecting
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 18,
                    color: isConnecting ? Colors.black45 : Colors.white, // Adjust text color when disabled
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Frame around the content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    // Device Control Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(create: (context) => LocationData()),
                                ChangeNotifierProvider(create: (_) => LocationMapProvider()),
                              ],
                              child: DeviceControlScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Device Control',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Real-Time Depth Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(create: (_) => LocationData()),
                                ChangeNotifierProvider(create: (_) => LocationMapProvider()),
                              ],
                              child: RealTimeDepthScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View Real-Time Depth',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pre-Mapped Routes Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(create: (context) => LocationData()),
                                ChangeNotifierProvider(create: (_) => LocationMapProvider()),
                              ],
                              child: PreMappedRoutesScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View Pre-Mapped Routes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Wi-Fi State Bar with HeartbeatLine
  Widget _buildWifiStateBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Connection with HeartbeatLine
        Row(
          children: [
            // Heartbeat animation for App Connection
            HeartbeatLine(isLoading: isAppConnected),
            const SizedBox(width: 8),
            Text(
              isAppConnected ? 'App Connected' : 'App Disconnected',
              style: TextStyle(fontSize: 16, color: isAppConnected ? Colors.green : Colors.red),
            ),
          ],
        ),
        // Pi Online Status with HeartbeatLine
        Row(
          children: [
            // Heartbeat animation for Pi connection
            HeartbeatLine(isLoading: isPiOnline),
            const SizedBox(width: 8),
            Text(
              isPiOnline ? 'Pi Online' : 'Pi Offline',
              style: TextStyle(fontSize: 16, color: isPiOnline ? Colors.green : Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}