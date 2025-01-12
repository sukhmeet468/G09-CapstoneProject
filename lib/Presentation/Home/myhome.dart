import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Logic/Bluetooth%20Comm/ble_manager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/fleetprovisionmanager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';
import 'package:g9capstoneiotapp/Presentation/Device%20Control/devicecontrol.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/premappedview.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/RealTime-View/realtimedepthscreen.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/Cloud%20Storage/readstorage_functions.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAppConnected = false;
  bool isPiOnline = false;
  bool isConnecting = false;
  bool isBluetoothConnected = false;
  bool isConnectingBluetooth = false;
  bool isPiBluetoothOn = false;
  String prevHeartbeatValue = "";
  late Timer heartbeatTimer;
  bool isAppBluetoothConnected = false;

  @override
  void initState() {
    super.initState();
    startHeartbeatCheck();
  }

  void startHeartbeatCheck() {
    // Timer to check heartbeat every 1 minute
    heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      var locationdata = Provider.of<LocationData>(context, listen: false);
      safePrint("$prevHeartbeatValue - ${locationdata.heartbeatValue}");
      if (prevHeartbeatValue != locationdata.heartbeatValue) {
        prevHeartbeatValue = locationdata.heartbeatValue;
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

  Future<void> connectAction() async {
    // Simulate the connection process
    await downloadCertificateAndKeys();
    // read the pre mapped routes
    await listAndReadMaps();
    // Check if client is connected
    if (clientLocal.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        isAppConnected = true;
      });
      setState(() {
        isConnecting = true;
      });
    } else {
      setState(() {
        isAppConnected = false;
      });
    }
    setState(() {
      isAppConnected = true;
    });
  }

  Future<void> connectBluetooth() async {
    // call the function to connect to bluetooth service running in Rpi
    final success = await discoverAndConnectToBleDevice();
    setState(() {
      isBluetoothConnected = success;
      isAppBluetoothConnected = success;
      if(success){
        setState(() {
          isConnectingBluetooth = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Real-Time Depth and Location Display'),
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
                  minimumSize: const Size(double.infinity, 50), // Full width button
                  backgroundColor: isConnecting ? Colors.grey : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isConnecting ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 18,
                    color: isConnecting ? Colors.black45 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // App Bluetooth Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAppBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: isAppBluetoothConnected ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAppBluetoothConnected ? 'App Bluetooth Connected' : 'App Bluetooth Disconnected',
                    style: TextStyle(
                      fontSize: 16,
                      color: isAppBluetoothConnected ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bluetooth Connect Button
              ElevatedButton(
                onPressed: isConnectingBluetooth ? null : connectBluetooth,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width button
                  backgroundColor: isConnectingBluetooth ? Colors.grey : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isConnectingBluetooth ? 'Connected' : 'Connect Bluetooth',
                  style: TextStyle(
                    fontSize: 18,
                    color: isConnectingBluetooth ? Colors.black45 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Pi Bluetooth Status Bar
              _buildPiBluetoothStatusBar(),
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
                        minimumSize: const Size(double.infinity, 50),
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Real-Time Depth Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pre-Mapped Routes Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
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

  Widget _buildWifiStateBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App connection status
        Row(
          children: [
            Icon(
              isAppConnected ? Icons.wifi : Icons.wifi_off,
              color: isAppConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isAppConnected ? 'App Connected' : 'App Disconnected',
              style: TextStyle(
                fontSize: 16,
                color: isAppConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        // Pi online status
        Row(
          children: [
            Icon(
              isPiOnline ? Icons.wifi : Icons.wifi_off,
              color: isPiOnline ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isPiOnline ? 'Pi Online' : 'Pi Offline',
              style: TextStyle(
                fontSize: 16,
                color: isPiOnline ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPiBluetoothStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: isBluetoothConnected ? Colors.blue : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          isBluetoothConnected ? 'Pi Bluetooth Connected' : 'Pi Bluetooth Disconnected',
          style: TextStyle(
            fontSize: 16,
            color: isBluetoothConnected ? Colors.blue : Colors.red,
          ),
        ),
      ],
    );
  }
}
