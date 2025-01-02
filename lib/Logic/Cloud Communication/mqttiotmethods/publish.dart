import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void publishMessage(MqttServerClient client, String publishtopic, String msg) {
  safePrint("Publishing Message to topic: $publishtopic with message: $msg");
  // Publish to a topic of your choice after a slight delay, AWS seems to need this
  final builder = MqttClientPayloadBuilder();
  builder.addString(msg);
  // Important: AWS IoT Core can only handle QOS of 0 or 1. QOS 2 (exactlyOnce) will fail!
  client.publishMessage(publishtopic, MqttQos.atLeastOnce, builder.payload!);
}