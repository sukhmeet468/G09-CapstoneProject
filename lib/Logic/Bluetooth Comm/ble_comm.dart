import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/comm_manager/subscribe_manager.dart';

Future<List<String>> scanForDeviceIds(FlutterReactiveBle ble, Uuid serviceId) async {
  final List<String> deviceIds = [];
  late StreamSubscription<DiscoveredDevice> subscription;
  final completer = Completer<List<String>>();
  try {
    subscription = ble
        .scanForDevices(withServices: [serviceId], scanMode: ScanMode.lowLatency)
        .listen(
      (device) {
        if (!deviceIds.contains(device.id)) {
          deviceIds.add(device.id);
        }
      },
      onError: (error) {
        completer.completeError('Scan failed with error: $error');
      },
    );
    await Future.delayed(Duration(seconds: 5));
    completer.complete(deviceIds);
  } catch (e) {
    completer.completeError('Error during scan: $e');
  } finally {
    await subscription.cancel();
  }
  return completer.future;
}

Future<void> connectToDevice({
  required FlutterReactiveBle ble,
  required String deviceId,
  required Uuid serviceUuid,
  required Map<Uuid, List<Uuid>> servicesWithCharacteristics,
  Duration prescanDuration = const Duration(seconds: 5),
  Duration connectionTimeout = const Duration(seconds: 2),
}) async {
  late StreamSubscription<ConnectionStateUpdate> subscription;
  try {
    subscription = ble
        .connectToAdvertisingDevice(
          id: deviceId,
          withServices: [serviceUuid],
          prescanDuration: prescanDuration,
          servicesWithCharacteristicsToDiscover: servicesWithCharacteristics,
          connectionTimeout: connectionTimeout,
        )
        .listen(
      (connectionState) {
        // Handle connection state updates
        safePrint('Connection state: ${connectionState.connectionState}');
      },
      onError: (dynamic error) {
        // Handle a possible error
        safePrint('Connection error: $error');
      },
    );
  } catch (e) {
    safePrint('Error during connection: $e');
  } finally {
    await subscription.cancel();
  }
}

Future<void> subscribeToBleCharacteristic({
  required FlutterReactiveBle ble,
  required String deviceId,
  required Uuid serviceUuid,
  required Uuid characteristicUuid,
}) async {
  final characteristic = QualifiedCharacteristic(
    serviceId: serviceUuid,
    characteristicId: characteristicUuid,
    deviceId: deviceId,
  );
  // ignore: unused_local_variable
  late StreamSubscription<List<int>> subscription;
  try {
    subscription = ble.subscribeToCharacteristic(characteristic).listen(
      (data) async {
        String dataRecv = utf8.decode(data).toString();
        // Handle incoming data
        safePrint('Received data: $dataRecv');
        // update the provider to display on UI
        await handleReadValuesResponse(dataRecv);
      },
      onError: (dynamic error) {
        // Handle a possible error
        safePrint('Subscription error: $error');
      },
    );
  } catch (e) {
    safePrint('Error during subscription: $e');
  }
}

Future<void> writeToCharacteristic({
  required FlutterReactiveBle ble,
  required String serviceUuid,
  required String characteristicUuid,
  required String deviceId,
  required List<int> value,
}) async {
  final characteristic = QualifiedCharacteristic(
    serviceId: Uuid.parse(serviceUuid),
    characteristicId: Uuid.parse(characteristicUuid),
    deviceId: deviceId,
  );
  try {
    await ble.writeCharacteristicWithResponse(
      characteristic,
      value: value,
    );
    safePrint('Successfully wrote value to characteristic!');
  } catch (e) {
    safePrint('Error writing to characteristic: $e');
  }
}