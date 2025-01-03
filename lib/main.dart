import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/userinfo.dart';
import 'package:provider/provider.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Communication/mqttiotmethods/fleetprovisionmanager.dart';
import 'Logic/Cloud Config/Amplify/amplifyconfiguration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAttributes()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, storage]);

    // call Amplify.configure to use the initialized categories in your app
    await Amplify.configure(amplifyconfig);
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  downloadCertificateAndKeys();
                },
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          body: Center(
            child: Consumer<UserAttributes>(
              builder: (context, userAttributes, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Email: ${userAttributes.email}'),
                    Text('Username: ${userAttributes.username}'),
                    Text('Signed In: ${userAttributes.signedIn}'),
                    Text('Admin: ${userAttributes.isAdmin}'),
                    Text('Devices: ${userAttributes.devices.join(', ')}'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
