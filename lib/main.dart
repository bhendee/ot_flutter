import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tableaux Test',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const TableauPage(title: 'Tableaux Demo'),
    );
  }
}

class TableauPage extends StatefulWidget {
  const TableauPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TableauPage> createState() => _TableauPageState();
}

class _TableauPageState extends State<TableauPage> {
    var tableRows = [['hi']];
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData:true);
    if (result != null) {
      PlatformFile file = result.files.first;
      print(file);
      if(file.bytes != null) {
        final String text = utf8.decode(file.bytes!);
        final tsvList = const CsvToListConverter(fieldDelimiter: '\t').convert(text);
        setState(() {
            tableRows = [for (final row in tsvList) [for (final item in row) item.toString()]];
        });
      }
      
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Table(
                border: TableBorder.all(width: 0.5, color: Colors.grey),
                children: [
                    for (final row in tableRows) TableRow(children: [
                        for (final item in row) TableCell(child: Text(item))
                    ])
                ]
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: _pickFile,
        child: const Text('Import Tab-Separated Tableaux'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
