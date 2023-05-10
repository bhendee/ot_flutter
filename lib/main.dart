import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

void main() {
    runApp(const OTApp());
}

class OTApp extends StatelessWidget {
    const OTApp({super.key});
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
        title: 'Tableaux Test',
        theme: ThemeData(
            useMaterial3: true,
        ),
        home: const TableauPage(title: 'Tableaux Demo'),
        );
    }
}

class TableauPage extends StatefulWidget {
    const TableauPage({super.key, required this.title});
    final String title;

    @override
    State<TableauPage> createState() => _TableauPageState();
}

class _TableauPageState extends State<TableauPage> {
    var tableRows = [['']];
    Future<void> _pickFile() async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(withData:true);
        if (result != null) {
        PlatformFile file = result.files.first;
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
        return Scaffold(
        appBar: AppBar(
            title: Text(widget.title),
        ),
        body: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
                Table(
                    border: TableBorder.all(width: 0.5, color: Theme.of(context).dividerColor),
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
        ),
        );
    }
}
