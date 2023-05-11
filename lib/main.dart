import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'tableaux.dart';
import 'package:editable/editable.dart';

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
        home: const TableauPage(title: 'Tableaux Demeaux'),
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
    Tableaux tableaux = Tableaux([], []);
    Map<Tableau, GlobalKey<EditableState>> _editableKeys = {};
    /// allows user to pick a tsv file for tableauxfication
    Future<void> _pickFile() async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(withData:true);
        if (result != null) {
        PlatformFile file = result.files.first;
        if(file.bytes != null) {
            final String text = utf8.decode(file.bytes!);
            final List<List<String>> tsvList = const CsvToListConverter(fieldDelimiter: '\t').convert(text, shouldParseNumbers: false);
            final tableaux = Tableaux.fromOTHelpList(tsvList);
            setState(() {
                this.tableaux = tableaux;
                _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
            });
        }
        
        }
    }

    void _updateTableaux(String s) {
        setState(() {
            tableaux = Tableaux.fromEditables([for (Tableau t in tableaux) {'cols': _editableKeys[t]?.currentState?.columns, 'rows': _editableKeys[t]?.currentState?.rows, 'edits': _editableKeys[t]?.currentState?.editedRows}]);
            _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: Text(widget.title),
        ),
        body: Flex(
                direction: Axis.vertical,
                children: [
                    for (Tableau t in tableaux)
                            Editable(
                                key: _editableKeys[t],
                                columns: t.toEditableLists()['cols'],
                                rows: t.toEditableLists()['rows'],
                                trHeight: 40.0,
                                onSubmitted: _updateTableaux,
                            ),
                ],
            ),
        floatingActionButton: ElevatedButton(
            onPressed: _pickFile,
            child: const Text('Import Tab-Separated Tableaux'),
        ),
        );
    }
}
