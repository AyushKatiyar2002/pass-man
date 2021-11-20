import 'package:flutter/material.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/utils/utils.dart';

class AddUpdateNote extends StatefulWidget {
  static const route = '/add-update-note';

  const AddUpdateNote({Key? key}) : super(key: key);

  @override
  _AddUpdateNoteState createState() => _AddUpdateNoteState();
}

class _AddUpdateNoteState extends State<AddUpdateNote> {
  final titleController = TextEditingController();
  final noteController = TextEditingController();

  void onSubmit() {
    final title = titleController.text.trim();
    final note = noteController.text;
    if (title.isEmpty || note.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => CommonAlertDialog(
          (title.isEmpty ? 'Title' : 'Note') + ' cannot be empty',
        ),
      );
      return;
    }
    print(title);
    print(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Globals.kBackButton,
        title: Text('Add/Update Note'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: Globals.webMaxWidth),
            padding: Globals.kScreenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Title',
                  ),
                ),
                Globals.kSizedBox,
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Write your note here...',
                  ),
                  textInputAction: TextInputAction.newline,
                  minLines: 10,
                  maxLines: 10,
                ),
                Globals.kSizedBox,
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onSubmit,
        label: Text("Submit"),
      ),
    );
  }
}
