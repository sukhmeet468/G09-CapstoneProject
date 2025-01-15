import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:g9capstoneiotapp/Logic/Bluetooth%20Comm/ble_manager.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Config/Amplify/configure.dart';
import 'package:g9capstoneiotapp/Presentation/Authentication/login.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/realtimeinfo.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/userinfo.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKeyhome = GlobalKey<NavigatorState>();
final FlutterReactiveBle ble = FlutterReactiveBle();

void main() async {
  // ensure widgets are fully initialized
  WidgetsFlutterBinding.ensureInitialized();
  // configure Amplify
  await configureAmplify();
  // Request permissions for bluetooth services
    await requestPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAttributes()),
        ChangeNotifierProvider(create: (_) => LocationData()),
        ChangeNotifierProvider(create: (_) => LocationMapProvider()),
      ],
      child: MaterialApp(
        home: MyLogin(),
      ),
    ),
  );
}
