import '../models/note.dart';
import 'note_editor_screen.dart';
import '../helpers/file_helper.dart';
import 'package:flutter/material.dart';

enum SortType { terbaru, terlama }

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final FileHelper _fileHelper = FileHelper();

  List<Note> _notes = [];

  bool _isLoading = true;

  SortType _sortType = SortType.terbaru;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _sortNotes() {
    switch (_sortType) {
      case SortType.terbaru:
        _notes.sort((a, b) => b.id.compareTo(a.id));
        break;

      case SortType.terlama:
        _notes.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _fileHelper.getAllNotes();

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _sortNotes();
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Catatan'),
          content: Text('Yakin ingin menghapus "${note.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _fileHelper.deleteNote(note.id);

      _loadNotes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada catatan', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          radius: 24,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.image, size: 16),

                const SizedBox(width: 4),

                Text('${note.imageCount} lampiran'),
              ],
            ),
          ],
        ),

        onTap: () {
          _openEditor(note: note);
        },

        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _openEditor(note: note);
            }

            if (value == 'delete') {
              _deleteNote(note);
            }
          },
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sortType) {
      case SortType.terbaru:
        return 'Terbaru';

      case SortType.terlama:
        return 'Terlama';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Taking App'),

        actions: [
          PopupMenuButton<SortType>(
            tooltip: 'Urutkan',

            icon: const Icon(Icons.sort),

            onSelected: (value) {
              setState(() {
                _sortType = value;
                _sortNotes();
              });
            },

            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortType.terbaru,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _sortType == SortType.terbaru
                          ? Colors.green
                          : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('Terbaru'),
                  ],
                ),
              ),

              PopupMenuItem(
                value: SortType.terlama,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _sortType == SortType.terlama
                          ? Colors.green
                          : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('Terlama'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotes),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadNotes,
                    child: ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];

                        return _buildNoteCard(note, index);
                      },
                    ),
                  ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openEditor();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
