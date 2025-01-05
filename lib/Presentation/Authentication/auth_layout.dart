import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {

  const CustomScaffold({
    super.key, 
    required this.state,
    required this.body,
    this.footer,
  });

  final AuthenticatorState state;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Logo (replace with an image)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Container(
                  width: 120, // Adjust the width as needed
                  height: 120, // Adjust the height as needed
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white, // Customize the border color
                      width: 2.0, // Customize the border width
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/photos/logo.jpeg',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              )
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: body,
            ),
          ],
        ),
      ),
    ),
    persistentFooterButtons: footer != null ? [footer!] : null,
  );
}

}
