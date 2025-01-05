import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Logic/Cloud%20Config/Amplify/configure.dart';
import 'package:g9capstoneiotapp/Presentation/Authentication/login.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/userinfo.dart';
import 'package:provider/provider.dart';

void main() async {
  // ensure widgets are fully initialized
  WidgetsFlutterBinding.ensureInitialized();
  // configure Amplify
  await configureAmplify();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAttributes()),
      ],
      child: MyLogin(),
    ),
  );
}
