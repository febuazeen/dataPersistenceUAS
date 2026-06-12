class Note {
  final String id;
  final String title;
  final String content;

  final int imageCount;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.imageCount = 0,
  });
}
