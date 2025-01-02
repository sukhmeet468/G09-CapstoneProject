import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';

Future<void> subMQTTTopics() async {
  //subscribe to all the Topics for all stations
  String topicprefix = "g9capstone/#";
  subscribeToTopic(clientLocal, topicprefix);
}