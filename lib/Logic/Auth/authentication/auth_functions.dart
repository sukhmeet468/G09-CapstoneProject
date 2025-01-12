//get the user attributes
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/userinfo.dart';

Future<List<AuthUserAttribute>?> fetchCurrentUserAttributes() async {
  UserAttributes userInfo = UserAttributes();
  try {
    final result = await Amplify.Auth.fetchUserAttributes();
    String email = "";
    String name = "";
    for (final element in result) {
      if(element.userAttributeKey == AuthUserAttributeKey.email){
        email = element.value;
      } else if(element.userAttributeKey == AuthUserAttributeKey.name){
        name = element.value;
      }
    }
    userInfo.setEmail = email;
    userInfo.setUsername = name;
    userInfo.setSignedIn = true;

    return result;
  } on AuthException catch (e) {
    safePrint('Error fetching user attributes: ${e.message}');
  }
  return null;
}