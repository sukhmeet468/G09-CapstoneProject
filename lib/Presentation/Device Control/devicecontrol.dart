import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Logic/Bluetooth%20Comm/ble_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceControlScreen extends StatefulWidget {
  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool isStartEnabled = true;
  bool isStopEnabled = false;
  bool isUploadMapEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isStartEnabled = prefs.getBool('isStartEnabled') ?? true;
      isStopEnabled = prefs.getBool('isStopEnabled') ?? false;
      isUploadMapEnabled = prefs.getBool('isUploadMapEnabled') ?? false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isStartEnabled', isStartEnabled);
    prefs.setBool('isStopEnabled', isStopEnabled);
    prefs.setBool('isUploadMapEnabled', isUploadMapEnabled);
  }

  Future<void> onStartPressed() async {
    await sendStart(); // Assume this is implemented elsewhere
    setState(() {
      isStartEnabled = false;
      isStopEnabled = true;
    });
    _saveState();
  }

  Future<void> onStopPressed() async {
    await sendStop(); // Assume this is implemented elsewhere
    setState(() {
      isStopEnabled = false;
      isUploadMapEnabled = false; // Temporarily disable Upload Map
    });
    _saveState();

    // Add a 10-second delay before enabling the Upload Map button
    await Future.delayed(const Duration(seconds: 10));

    setState(() {
      isUploadMapEnabled = true;
    });
    _saveState();
  }


  Future<void> onUploadMapPressed() async {
    await sendUpload(); // Assume this is implemented elsewhere
    setState(() {
      isUploadMapEnabled = false;
      isStartEnabled = true;
    });
    _saveState();
  }

  // Button style for enabled state
  ButtonStyle enabledButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Blue color when enabled
  );

  // Button style for disabled state
  ButtonStyle disabledButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey, // Grey color when disabled
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isStartEnabled ? onStartPressed : null,
              style: isStartEnabled ? enabledButtonStyle : disabledButtonStyle,
              child: const Text('START'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isStopEnabled ? onStopPressed : null,
              style: isStopEnabled ? enabledButtonStyle : disabledButtonStyle,
              child: const Text('STOP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploadMapEnabled ? onUploadMapPressed : null,
              style:
                  isUploadMapEnabled ? enabledButtonStyle : disabledButtonStyle,
              child: const Text('UPLOAD MAP'),
            ),
          ],
        ),
      ),
    );
  }
}