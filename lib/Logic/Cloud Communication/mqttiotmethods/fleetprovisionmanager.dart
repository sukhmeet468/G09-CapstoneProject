import 'dart:convert';
import 'package:g9capstoneiotapp/Logic/App%20Logic/authentication/auth_functions.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/comm_manager/subscribe_manager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/connect.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/publish.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/subscribe.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/userinfo.dart';
import 'package:g9capstoneiotapp/Storage/Cloud%20Storage/readStorage_functions.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttServerClient clientG = MqttServerClient.withPort("", "clientId", 0);
UserAttributes userValue = UserAttributes();

String localcertToken = "";
String localcertId = "";
String localKey = "";
String localcertPem = "";

String requestTopic = "\$aws/certificates/create/json";
String responseTopic = "\$aws/certificates/create/json/accepted";
String registerTopic =
    "\$aws/provisioning-templates/g9Capstone_appmqtttemplate/provision/json";
String registerResponse =
    "\$aws/provisioning-templates/g9Capstone_appmqtttemplate/provision/json/accepted";

void setClient(MqttServerClient client) {
  clientG = client;
}

Future<void> createpayload(String certificateOwnershipToken) async {
  final requestPayload = {
    "certificateOwnershipToken": certificateOwnershipToken,
  };
  final requestJson = json.encode(requestPayload);
  //RegisterThing Provisions a thing using a pre-defined template.
  publishMessage(clientG, registerTopic, requestJson.toString());
}

Future<void> createKeysAndCertificate() async {
  // use the claim certificates to connect to AWS IoT
  MqttServerClient client = await connect();
  setClient(client);
  //Call CreateCertificateFromCsr to generate a certificate from a certificate 
  //signing request that keeps its private key secure.
  //Creates a certificate from a certificate signing request (CSR). 
  //AWS IoT provides client certificates that are signed by the Amazon Root certificate authority (CA).
  //The new certificate has a PENDING_ACTIVATION status. When you call RegisterThing to 
  //provision a thing with this certificate, the certificate status changes to ACTIVE or INACTIVE as described in the template.
  //response Payload
  subscribeToTopic(client, responseTopic);
  publishMessage(client, requestTopic, "");
}

Future<void> downloadCertificateAndKeys() async {
  //get the details of the user signed in
  await fetchCurrentUserAttributes();
  //check for the certs and keys saved for the user, if not create and then connect to the IoT Core through a private secure channel
  String dataMap = await downloadToMemory("${userValue.email}/IoTData");
  if (dataMap != "") {
    Map<String, dynamic> jsonData = json.decode(dataMap);
    localcertId = jsonData["certificateId"];
    localcertPem = jsonData["certificatePem"];
    localcertToken = jsonData["certificateOwnershipToken"];
    localKey = jsonData["privateKey"];
    MqttServerClient client = await connectLocalP(localcertPem, localKey);
    setLocalClient(client);
  } else {
    // Handle the case where downloadToMemory returns an empty map
    await createKeysAndCertificate();
  }
  // subscribe to all topics
  await subMQTTTopics();
}