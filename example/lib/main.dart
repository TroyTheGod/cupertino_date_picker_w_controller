import 'package:cupertino_date_picker_w_controller/cupertino_date_picker_w_controller.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CustomDatePickerController controller;
  String date = DateTime.now().toString();

  @override
  void initState() {
    super.initState();
    controller = CustomDatePickerController(
      minimumDate: DateTime(1900),
      maximumDate: DateTime(2100),
      initialDateTime: DateTime.now(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(date),
            SizedBox(
              height: 300.0,
              width: MediaQuery.of(context).size.width - 40.0,
              child: CustomDatePicker(
                controller: controller,
                onDateTimeChange: (newDate) {
                  setState(() {
                    date = newDate.toString();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
