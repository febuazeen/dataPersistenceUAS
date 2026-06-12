import 'dart:io';
import '../models/note.dart';
import '../helpers/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';



class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FileHelper _fileHelper = FileHelper();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  late final String _noteId;

  bool _isSaving = false;

  final Map<int, File?> _images = {1: null, 2: null, 3: null};

  bool get _isEdit => widget.note != null;

  int get imageCount => _images.values.where((e) => e != null).length;

  @override
  void initState() {
    super.initState();

    _noteId = widget.note?.id ?? _fileHelper.generateNoteId();

    if (_isEdit) {
      _titleController.text = widget.note!.title;

      _contentController.text = widget.note!.content;
    }

    _loadExistingImages();
  }

  Future<void> _loadExistingImages() async {
    for (int slot = 1; slot <= 3; slot++) {
      _images[slot] = await _fileHelper.getNoteImage(_noteId, slot);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    if (imageCount >= 3) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    for (int slot = 1; slot <= 3; slot++) {
      if (_images[slot] == null) {
        setState(() {
          _images[slot] = file;
        });
        break;
      }
    }
  }

  void _removeImage(int slot) {
    setState(() {
      _images[slot] = null;
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _fileHelper.saveNote(
        _noteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      for (int slot = 1; slot <= 3; slot++) {
        final image = _images[slot];

        if (image == null) {
          await _fileHelper.deleteNoteImage(_noteId, slot);
        } else {
          await _fileHelper.saveNoteImage(_noteId, slot, image.path);
        }
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildImageSlot(int slot) {
    final image = _images[slot];

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null
                ? Image.file(image, width: 180, height: 200, fit: BoxFit.cover)
                : Container(
                    width: 180,
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Center(child: Text('Slot $slot')),
                  ),
          ),
          if (image != null)
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeImage(slot),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [_buildImageSlot(1), _buildImageSlot(2), _buildImageSlot(3)],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          IconButton(onPressed: _saveNote, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lampiran Gambar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildImages(),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: imageCount < 3 ? _pickImage : null,
              icon: const Icon(Icons.image),
              label: Text('Tambah Gambar ($imageCount/3)'),
            ),
            const SizedBox(height: 20),
            if (_isSaving) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
