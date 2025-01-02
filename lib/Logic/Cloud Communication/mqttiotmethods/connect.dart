import 'dart:convert';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<MqttServerClient> connect() async {
  //call the function to connect to the AWS
  // Your AWS IoT Core endpoint url
  const url = 'a265o0aqbr1bnh-ats.iot.ca-central-1.amazonaws.com';
  // AWS IoT MQTT default port
  const port = 8883;
  // The client id unique to your device
  const clientId = 'g9IoTcapstone';
  // Create the client
  final client = MqttServerClient.withPort(url, clientId, port);
  // Set secure
  client.secure = true;
  // Set Keep-Alive
  client.keepAlivePeriod = 30;
  // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will not receive a connect ack with the response code
  client.setProtocolV311();
  // logging if you wish
  client.logging(on: false);
  // Set the security context as you need, note this is the standard Dart SecurityContext class.
  // If this is incorrect the TLS handshake will abort and a Handshake exception will be raised,
  // no connect ack message will be received and the broker will disconnect.
  // For AWS IoT Core, we need to set the AWS Root CA, device cert & device private key
  // Note that for Flutter users the parameters above can be set in byte format rather than file paths
  final context = SecurityContext.defaultContext;
  // Load and convert certificates from assets
  final rootCACertificate =
      await rootBundle.loadString('assets/certs/AmazonRootCA1.pem');
  final deviceCertificate = await rootBundle.loadString(
      'assets/certs/29808742218af61aa5eab9c21e3f8494c94e2c5e98020a0e57a6e63c2e9d0e10-certificate.pem.crt');
  final privateKey = await rootBundle.loadString(
      'assets/certs/29808742218af61aa5eab9c21e3f8494c94e2c5e98020a0e57a6e63c2e9d0e10-private.pem.key');
  context.setTrustedCertificatesBytes(utf8.encode(rootCACertificate));
  context.useCertificateChainBytes(utf8.encode(deviceCertificate));
  context.usePrivateKeyBytes(utf8.encode(privateKey));
  //set the securities
  client.securityContext = context;
  // Setup the connection Message
  final connMess =
      MqttConnectMessage().withClientIdentifier('flutter_app').startClean();
  client.connectionMessage = connMess;
  // Connect the client
  try {
    safePrint('MQTT client connecting to AWS IoT using certificates....');
    await client.connect();
  } on Exception catch (e) {
    safePrint('MQTT client exception - $e');
    client.disconnect();
    exit(-1);
  }
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    safePrint('MQTT client connected to AWS IoT');
  } else {
    safePrint(
        'ERROR MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
  }
  return client;
}

void disconnectClient(MqttServerClient client) {
  client.disconnect();
  if (client.connectionStatus!.state == MqttConnectionState.disconnected) {
    safePrint("Mqtt Client disconnected! ");
  }
}

Future<MqttServerClient> connectLocalP(
    String certificatePerm, String privateKeyP) async {
  //call the function to connect to the AWS
  // Your AWS IoT Core endpoint url
  const url = 'a265o0aqbr1bnh-ats.iot.ca-central-1.amazonaws.com';
  // AWS IoT MQTT default port
  const port = 8883;
  // The client id unique to your device
  const clientId = 'g9IoTcapstone';
  // Create the client
  final client = MqttServerClient.withPort(url, clientId, port);
  // Set secure
  client.secure = true;
  // Set Keep-Alive
  client.keepAlivePeriod = 60;
  // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will not receive a connect ack with the response code
  client.setProtocolV311();
  // logging if you wish
  client.logging(on: false);
  // Set the security context as you need, note this is the standard Dart SecurityContext class.
  // If this is incorrect the TLS handshake will abort and a Handshake exception will be raised,
  // no connect ack message will be received and the broker will disconnect.
  // For AWS IoT Core, we need to set the AWS Root CA, device cert & device private key
  // Note that for Flutter users the parameters above can be set in byte format rather than file paths
  final context = SecurityContext.defaultContext;
  // Load and convert certificates from assets
  final rootCACertificate =
      await rootBundle.loadString('assets/certs/AmazonRootCA1.pem');
  context.setTrustedCertificatesBytes(utf8.encode(rootCACertificate));
  context.useCertificateChainBytes(utf8.encode(certificatePerm));
  context.usePrivateKeyBytes(utf8.encode(privateKeyP));
  //set the securities
  client.securityContext = context;
  // Setup the connection Message
  final connMess =
      MqttConnectMessage().withClientIdentifier('IndusIoT_App').startClean();
  client.connectionMessage = connMess;
  // Connect the client
  try {
    safePrint(
        'MQTT client connecting to AWS IoT using permanent local certificates....');
    await client.connect();
  } on Exception catch (e) {
    safePrint('MQTT client exception - $e');
    client.disconnect();
    exit(-1);
  }
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    safePrint(
        'MQTT client connected to AWS IoT using the local permanent certificates');
  } else {
    safePrint(
        'ERROR MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
  }
  return client;
}