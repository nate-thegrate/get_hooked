import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

/// Compare this code to https://main-api.flutter.dev/flutter/widgets/Form-class.html
///
/// - more concise
/// - only the [TextField] rebuilds
class FormExampleApp extends StatelessWidget {
  const FormExampleApp({super.key});

  static final email = Get.it('');
  static final validation = Get.it<String?>(null);

  static Widget textField(BuildContext context) => TextField(
    decoration: InputDecoration(hintText: 'Enter your email', errorText: ref.watch(validation)),
    onChanged: email.emit,
  );

  static const button = Padding(
    padding: EdgeInsets.symmetric(vertical: 16.0),
    child: ElevatedButton(onPressed: validate, child: Text('Submit')),
  );

  static void validate() {
    // Any relevant validation logic can be added here.
    // Generally it will set non-null error text for invalid fields.
    final bool valid = email.value.isNotEmpty;
    validation.emit(valid ? null : 'Please enter some text.');

    if (valid) {
      // Process data.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Form Sample')),
        drawer: const ScreenSelect(),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[HookBuilder(textField), button],
        ),
      ),
    );
  }
}
