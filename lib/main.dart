import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'tableaux.dart';
import 'package:editableaux/editableaux.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

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
    GlobalKey<FormBuilderState> _constraintFormKey = GlobalKey<FormBuilderState>();
    GlobalKey<FormBuilderState> _inputFormKey = GlobalKey<FormBuilderState>();
    String fileName = 'tableaux';
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
                fileName = file.name.substring(0, file.name.length - (file.extension?.length ?? 0) - 1);
                this.tableaux = tableaux;
                _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
            });
        }
        
        }
    }

    /// updates constraint changes based on form values
    void _writeConstraintChange() {
        setState(() {
            tableaux = tableaux.changeConstraints(_constraintFormKey.currentState!.fields);
            _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
            _constraintFormKey = GlobalKey<FormBuilderState>();
        });
    }
    /// allows user to add or modify constraints
    void _editConstraints() {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                List<Constraint> constraints = tableaux.constraints;
                return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setAlertState)
                    {

                        return FormBuilder(
                            key: _constraintFormKey,
                            child:AlertDialog(
                                title: const Text('Constraint Editing'),
                                content: Column(
                                        children: <Widget>[
                                            for (Constraint c in constraints) 
                                            FormBuilderTextField(name: '$c', initialValue: '$c')
                                        ] + [
                                            TextButton(
                                                onPressed: () {
                                                    setAlertState(() {
                                                        constraints = constraints + [Constraint('Constraint ${constraints.length}')];
                                                    });
                                                },
                                                child: const Text('Add Constraint'),
                                            )
                                        ]
                                    ),
                                actions: [
                                    TextButton(
                                        child: const Text('Save'),
                                        onPressed: () {
                                            Navigator.pop(context);
                                            _writeConstraintChange();
                                        }
                                    )
                                ],
                            )
                        );
                    }
                );
            }
        );
    }
    /// shows a SnackBar with provided message
    void _alert(String s) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s),
        ));
    }

    /// updates Tableaux with new data from Editable.
    void _updateTableaux(String s) {
        try {
            setState(() {
                tableaux = Tableaux.fromEditables([for (Tableau t in tableaux) {'cols': _editableKeys[t]?.currentState?.columns, 'rows': _editableKeys[t]?.currentState?.rows, 'edits': _editableKeys[t]?.currentState?.editedRows}]);
                _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
            });
        } on FormatException {
            _alert('Seems like you put too many victors. Changes not saved.');
        } on CastError {
            _alert('Seems like you forgot a victor Changes not saved.');
        } catch(e) {
            _alert('Seems like you messed up the Tableaux. Changes not saved.');
        }
    }

    /// saves Tableaux to a file
    void _saveTableaux() {
        List<List<String>> othelp = tableaux.toOTHelpList();
        String text = const ListToCsvConverter(fieldDelimiter: '\t').convert(othelp);
        Uint8List bytes = Uint8List.fromList(utf8.encode(text));
        FileSaver.instance.saveFile(name:fileName, bytes:bytes, ext:'.txt', mimeType: MimeType.text);
    }

    /// displays and handles dialog for editing input forms
    void _editInputs() {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                List<String> input = [for (Tableau t in tableaux) t.input];
                return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setAlertState)
                    {

                        return FormBuilder(
                            key: _inputFormKey,
                            child:AlertDialog(
                                title: const Text('Input Editing'),
                                content: Column(
                                        children: <Widget>[
                                            for (String s in input) 
                                            FormBuilderTextField(name: s, initialValue: s)
                                        ] + [
                                            TextButton(
                                                onPressed: () {
                                                    setAlertState(() {
                                                        input = input + ['Input ${input.length}'];
                                                    });
                                                },
                                                child: const Text('Add Input'),
                                            )
                                        ]
                                    ),
                                actions: [
                                    TextButton(
                                        child: const Text('Save'),
                                        onPressed: () {
                                            Navigator.pop(context);
                                            _writeInputChange();
                                        }
                                    )
                                ],
                            )
                        );
                    }
                );
            }
        );
    }
    /// updates input changes based on form values
    void _writeInputChange() {
        setState(() {
            tableaux = tableaux.changeInputs(_inputFormKey.currentState!.fields);
            _editableKeys = {for (Tableau t in tableaux) t:GlobalKey<EditableState>()};
            _inputFormKey = GlobalKey<FormBuilderState>();
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.title),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveTableaux,
                    )
                ],
            ),
            body: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: <Widget>[
                        TextField(
                            controller: TextEditingController(
                                text:fileName
                            ),
                            onSubmitted: (String s) {
                                setState(() {
                                    fileName = s;
                                });
                            }
                        )
                    ] +
                    [
                        for (Tableau t in tableaux)
                                Editable(
                                    key: _editableKeys[t],
                                    thSize: 14,
                                    thWeight: FontWeight.bold,
                                    columns: t.toEditableLists()['cols']!,
                                    rows: t.toEditableLists()['rows']!,
                                    trHeight: 40.0,
                                    tdPaddingTop: 0.0,
                                    onSubmitted: _updateTableaux,
                                    showCreateButton: true,
                                    showRemoveIcon: true,
                                    createButtonAlign: CrossAxisAlignment.end,
                                ),
                    ],
                ),
            floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    ElevatedButton(
                        onPressed: _pickFile,
                        child: const Text('Import Tab-Separated Tableaux'),
                    ),
                    ElevatedButton(
                        onPressed: _editConstraints,
                        child: const Text('Edit Constraints'),
                    ),
                    ElevatedButton(
                        onPressed: _editInputs,
                        child: const Text('Edit Inputs'),
                    )
                ],
            ),
        );
    }
}
