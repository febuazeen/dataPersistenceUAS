import 'dart:io';
import '../models/note.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';



class FileHelper {
  static final FileHelper _instance = FileHelper._internal();

  FileHelper._internal();

  factory FileHelper() => _instance;

  Future<Directory> _getNotesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();

    final notesDir = Directory(join(docsDir.path, 'notes'));

    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    return notesDir;
  }

  String generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> saveNote(String noteId, String title, String content) async {
    final notesDir = await _getNotesDirectory();

    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final file = File(join(noteDir.path, 'content.txt'));

    await file.writeAsString('$title\n$content');
  }

  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();

    final contentFile = File(join(notesDir.path, noteId, 'content.txt'));

    if (!await contentFile.exists()) {
      return null;
    }

    final rawContent = await contentFile.readAsString();

    final lines = rawContent.split('\n');

    final title = lines.isNotEmpty ? lines.first : '';

    final content = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    int imageCount = 0;

    for (int i = 1; i <= 3; i++) {
      final imageFile = File(join(notesDir.path, noteId, 'image_$i.jpg'));

      if (await imageFile.exists()) {
        imageCount++;
      }
    }

    return Note(
      id: noteId,
      title: title,
      content: content,
      imageCount: imageCount,
    );
  }

  Future<List<Note>> getAllNotes() async {
    final notesDir = await _getNotesDirectory();

    final List<Note> notes = [];

    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        final noteId = basename(entity.path);

        final note = await readNote(noteId);

        if (note != null) {
          notes.add(note);
        }
      }
    }

    notes.sort((a, b) => b.id.compareTo(a.id));

    return notes;
  }

  Future<void> saveNoteImage(
    String noteId,
    int index,
    String sourcePath,
  ) async {
    final notesDir = await _getNotesDirectory();

    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      return;
    }

    final originalBytes = await sourceFile.readAsBytes();

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    final targetFile = File(join(noteDir.path, 'image_$index.jpg'));

    await targetFile.writeAsBytes(compressedBytes);
  }

  Future<void> deleteNoteImage(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();

    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));

    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  Future<File?> getNoteImage(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();

    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));

    if (await imageFile.exists()) {
      return imageFile;
    }

    return null;
  }

  Future<List<File>> getNoteImages(String noteId) async {
    final notesDir = await _getNotesDirectory();

    final List<File> images = [];

    for (int i = 1; i <= 3; i++) {
      final imageFile = File(join(notesDir.path, noteId, 'image_$i.jpg'));

      if (await imageFile.exists()) {
        images.add(imageFile);
      }
    }

    return images;
  }

  Future<void> deleteNote(String noteId) async {
    final notesDir = await _getNotesDirectory();

    final noteDir = Directory(join(notesDir.path, noteId));

    if (await noteDir.exists()) {
      await noteDir.delete(recursive: true);
    }
  }
}
