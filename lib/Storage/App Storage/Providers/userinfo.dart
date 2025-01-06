import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

String _email = "";
String _username = "";
bool _signedIn = false;
bool _isAdmin = false;
List<String> _devices = [];

class UserAttributes extends ChangeNotifier {

  String get email => _email;
  set setEmail(String value) {
    _email = value;
    safePrint(_email);
    try {
      notifyListeners();
    } on Exception catch (e) {
      safePrint("cannot notify: $e");
    }
  }

  String get username => _username;
  set setUsername(String value) {
    _username = value;
    safePrint(_username);
    try {
      notifyListeners();
    } on Exception catch (e) {
      safePrint("cannot notify: $e");
    }
  }

  bool get signedIn => _signedIn;
  set setSignedIn(bool value) {
    _signedIn = value;
    safePrint(_signedIn);
    try {
      notifyListeners();
    } on Exception catch (e) {
      safePrint("cannot notify: $e");
    }
  }

  bool get isAdmin => _isAdmin;
  set setisAdmin(bool value) {
    _isAdmin = value;
    safePrint(_isAdmin);
    try {
      notifyListeners();
    } on Exception catch (e) {
      safePrint("cannot notify: $e");
    }
  }

  List<String> get devices => _devices;
  set setDevices(List<String> list){
    _devices = list;
    notifyListeners();
  }

  void addDevice(String siteCode){
    _devices.add(siteCode);
    notifyListeners();
  }
  
}
