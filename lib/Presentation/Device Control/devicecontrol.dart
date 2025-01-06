import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/publish.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';

class DeviceControlScreen extends StatefulWidget {
  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool isStartEnabled = true;
  bool isStopEnabled = false;
  bool isUploadMapEnabled = false;

  // Function to simulate publishing a message (for example, print the JSON)
  void publishMsg(String messageType) {
    String message = "";
    switch (messageType) {
      case 'START':
        message = "START";
        break;
      case 'STOP':
        message = "STOP";
        break;
      case 'UPLOAD_MAP':
        message = "UPLOAD";
        break;
    }
    // Call the publish message to send a message to Pi4 using MQTT
    publishMessage(clientLocal, "g9capstone/PiAction", message);
  }

  // Function to handle START button press
  void onStartPressed() {
    publishMsg('START');
    setState(() {
      isStartEnabled = false;
      isStopEnabled = true;
    });
  }

  // Function to handle STOP button press
  void onStopPressed() {
    publishMsg('STOP');
    setState(() {
      isStopEnabled = false;
      isUploadMapEnabled = true;
      isStartEnabled = true;
    });
  }

  // Function to handle UPLOAD MAP button press
  void onUploadMapPressed() {
    publishMsg('UPLOAD_MAP');
    setState(() {
      isUploadMapEnabled = false;
      isStartEnabled = true;
    });
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
              style: isUploadMapEnabled ? enabledButtonStyle : disabledButtonStyle,
              child: const Text('UPLOAD MAP'),
            ),
          ],
        ),
      ),
    );
  }
}