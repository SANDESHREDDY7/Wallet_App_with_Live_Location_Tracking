import 'dart:convert';

class NoteItem {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final String? imagePath;
  final String? pdfPath;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.imagePath,
    this.pdfPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'pdfPath': pdfPath,
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePath: map['imagePath'] as String?,
      pdfPath: map['pdfPath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteItem.fromJson(String source) => NoteItem.fromMap(json.decode(source) as Map<String, dynamic>);

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? timestamp,
    String? imagePath,
    String? pdfPath,
    bool clearImage = false,
    bool clearPdf = false,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      pdfPath: clearPdf ? null : (pdfPath ?? this.pdfPath),
    );
  }
}
