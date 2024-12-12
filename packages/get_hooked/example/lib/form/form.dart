import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

/// Compare this code to https://main-api.flutter.dev/flutter/widgets/Form-class.html
///
/// - more concise
/// - only the [TextField] rebuilds

class FormExampleApp extends StatelessWidget {
  const FormExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Form Sample')),
        drawer: const ScreenSelect(),
        body: const FormExample(),
      ),
    );
  }
}

final getEmail = Get.it('');
final getValidation = Get.it(true);

class FormExample extends Column {
  const FormExample({super.key})
    : super(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[HookBuilder(builder: textField), button],
      );

  static Widget textField(BuildContext context) => TextField(
    decoration: InputDecoration(
      hintText: 'Enter your email',
      errorText: Ref.watch(getValidation) ? null : 'Please enter some text',
    ),
    onChanged: getEmail.emit,
  );

  static const button = Padding(
    padding: EdgeInsets.symmetric(vertical: 16.0),
    child: ElevatedButton(onPressed: validate, child: Text('Submit')),
  );

  static void validate() {
    // Validate will act however you want it to!
    // Generally it will set non-null error text for invalid fields.
    final bool valid = getEmail.value.isNotEmpty;
    getValidation.emit(valid);

    if (valid) {
      // Process data.
    }
  }
}
