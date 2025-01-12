import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:g9capstoneiotapp/Logic/Bluetooth%20Comm/ble_comm.dart';
import 'package:permission_handler/permission_handler.dart';

String? deviceId; // Global variable to store the device ID

Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    if (await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location
      ].request();
    }
  }
}

Future<bool> discoverAndConnectToBleDevice() async {
  final FlutterReactiveBle ble = FlutterReactiveBle();
  final Uuid deviceCtrlServiceUuid = Uuid.parse("37dd28eb-b0e5-4714-b874-0fa1f50f88bf");
  final Uuid deviceCtrlCharUuid = Uuid.parse("9232ed36-2122-4773-b1c8-31c2d5114e96");
  final Uuid depthMonitorServiceUuid = Uuid.parse("cbc3bb98-e29b-4b8d-8a1b-3e90aa65a790");
  final Uuid depthMonitorCharUuid = Uuid.parse("6943ec7e-cb2e-4b44-9adc-7f5d12837bd1");
  try {
    // Discover devices advertising the Device Control Service
    final deviceIds = await scanForDeviceIds(ble, deviceCtrlServiceUuid);
    await Future.delayed(Duration(seconds: 1));
    safePrint('Discovered Device IDs: $deviceIds');
    if (deviceIds.isEmpty) {
      safePrint('No devices found advertising the Device Control Service.');
      return false; // Discovery failed
    }
    // Step 3: Connect to the first discovered device
    deviceId = deviceIds.first; // Use the first discovered device
    safePrint("Connecting to Device ID: $deviceId");
    await connectToDevice(
      ble: ble,
      deviceId: deviceId!,
      serviceUuid: deviceCtrlServiceUuid,
      servicesWithCharacteristics: {
        deviceCtrlServiceUuid: [deviceCtrlCharUuid],
      },
    );
    await Future.delayed(Duration(seconds: 2));
    // Step 4: Subscribe to Depth Monitor Characteristic
    await subscribeToBleCharacteristic(
      ble: ble,
      deviceId: deviceId!,
      serviceUuid: depthMonitorServiceUuid,
      characteristicUuid: depthMonitorCharUuid,
    );
    safePrint('Successfully connected and subscribed to BLE device.');
    return true; // All steps succeeded
  } catch (e) {
    safePrint('Error occurred during BLE operation: $e');
    return false; // Handle errors gracefully
  }
}

Future<void> sendStart() async {
  if (deviceId == null) {
    safePrint('Device is not connected.');
    return;
  }
  final Uuid deviceCtrlServiceUuid = Uuid.parse("37dd28eb-b0e5-4714-b874-0fa1f50f88bf");
  final Uuid deviceCtrlCharUuid = Uuid.parse("9232ed36-2122-4773-b1c8-31c2d5114e96");
  final startValue = utf8.encode('START'); // Encoding the string to UTF-8
  try {
    await writeToCharacteristic(
      ble: FlutterReactiveBle(),
      serviceUuid: deviceCtrlServiceUuid.toString(),
      characteristicUuid: deviceCtrlCharUuid.toString(),
      deviceId: deviceId!,
      value: startValue,
    );
    safePrint('Sent START command to device');
  } catch (e) {
    safePrint('Error sending START command: $e');
  }
}

Future<void> sendStop() async {
  if (deviceId == null) {
    safePrint('Device is not connected.');
    return;
  }
  final Uuid deviceCtrlServiceUuid = Uuid.parse("37dd28eb-b0e5-4714-b874-0fa1f50f88bf");
  final Uuid deviceCtrlCharUuid = Uuid.parse("9232ed36-2122-4773-b1c8-31c2d5114e96");
  final stopValue = utf8.encode('STOP'); // Encoding the string to UTF-8
  try {
    await writeToCharacteristic(
      ble: FlutterReactiveBle(),
      serviceUuid: deviceCtrlServiceUuid.toString(),
      characteristicUuid: deviceCtrlCharUuid.toString(),
      deviceId: deviceId!,
      value: stopValue,
    );
    safePrint('Sent STOP command to device');
  } catch (e) {
    safePrint('Error sending STOP command: $e');
  }
}

Future<void> sendUpload() async {
  if (deviceId == null) {
    safePrint('Device is not connected.');
    return;
  }
  final Uuid deviceCtrlServiceUuid = Uuid.parse("37dd28eb-b0e5-4714-b874-0fa1f50f88bf");
  final Uuid deviceCtrlCharUuid = Uuid.parse("9232ed36-2122-4773-b1c8-31c2d5114e96");
  final updateValue = utf8.encode('UPLOAD'); // Encoding the string to UTF-8
  try {
    await writeToCharacteristic(
      ble: FlutterReactiveBle(),
      serviceUuid: deviceCtrlServiceUuid.toString(),
      characteristicUuid: deviceCtrlCharUuid.toString(),
      deviceId: deviceId!,
      value: updateValue,
    );
    safePrint('Sent UPDATE command to device');
  } catch (e) {
    safePrint('Error sending UPDATE command: $e');
  }
}