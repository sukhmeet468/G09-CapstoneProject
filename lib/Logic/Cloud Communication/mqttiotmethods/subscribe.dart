import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/comm_manager/subscribe_manager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/connect.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/fleetprovisionmanager.dart';
import 'package:g9capstoneiotapp/Storage/Cloud%20Storage/writestorage_functions.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

String certificateOwnershipToken = "";
String certificateId = "";
String privateKey = "";
String certificatePem = "";
String thingName = "";

MqttServerClient clientLocal = MqttServerClient.withPort("", "clientId", 0);

void subscribeToTopic(MqttServerClient client, String topic) {
  safePrint("Subscribing to topic: $topic");
  client.subscribe(topic, MqttQos.atLeastOnce);
  client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
    final recMess = c[0].payload as MqttPublishMessage;
    String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    String topic = c[0].topic;
    if (topic == responseTopic) {
      await handleResponse(pt);
    } else if(topic == "g9capstone/readValues") {
      await handleReadValuesResponse(pt);
    } else if(topic == "g9capstone/piHeartbeat") {
      await handleHeartbeatResponse(pt);
    }
  });
}

Future<void> handleResponse(String value) async {
  safePrint(value);
  Map<String, dynamic> jsonData = json.decode(value);
  certificateId = jsonData["certificateId"];
  certificatePem = jsonData["certificatePem"];
  certificateOwnershipToken = jsonData["certificateOwnershipToken"];
  privateKey = jsonData["privateKey"];
  await createpayload(certificateOwnershipToken);
  //disconnect from the previous session
  disconnectClient(clientG);
  MqttServerClient client = await connectLocalP(certificatePem, privateKey);
  setLocalClient(client);
  uploadCertsDataAsFile("${userValue.email}/IoTData", value);
}

void setLocalClient(MqttServerClient client) {
  clientLocal = client;
}