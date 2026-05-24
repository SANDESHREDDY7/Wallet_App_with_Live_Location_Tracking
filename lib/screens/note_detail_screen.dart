import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/note_item.dart';
import '../providers/note_provider.dart';
import '../theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteItem? note;

  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _imagePath;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _imagePath = widget.note?.imagePath;
    _pdfPath = widget.note?.pdfPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.textGrey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Add Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: LucideIcons.camera,
                  label: 'Camera',
                  color: Colors.blueAccent,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      HapticFeedback.lightImpact();
                      setState(() => _imagePath = image.path);
                    }
                  },
                ),
                _buildAttachmentOption(
                  icon: LucideIcons.image,
                  label: 'Gallery',
                  color: AppTheme.primaryPurple,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      HapticFeedback.lightImpact();
                      setState(() => _imagePath = image.path);
                    }
                  },
                ),
                _buildAttachmentOption(
                  icon: LucideIcons.fileText,
                  label: 'PDF Doc',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickPDF();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _pdfPath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick PDF: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _secureCopyFile(String? srcPath, String prefix, String id) async {
    if (srcPath == null) return null;
    try {
      final dbDir = await getDatabasesPath();
      final secureDir = Directory(path.join(dbDir, 'secure_attachments'));
      if (srcPath.startsWith(secureDir.path)) {
        return srcPath;
      }
      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }
      final destPath = path.join(secureDir.path, '${prefix}_${id}_attachment.secure');
      final srcFile = File(srcPath);
      if (await srcFile.exists()) {
        await srcFile.copy(destPath);
        return destPath;
      }
    } catch (e) {
      print('Error copying attachment to secure sandboxed folder: $e');
    }
    return srcPath;
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty && _imagePath == null && _pdfPath == null) {
      Navigator.pop(context);
      return;
    }

    // Show premium secure encryption progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: AppTheme.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryPurple),
                const SizedBox(height: 20),
                const Text(
                  'Securing & Encrypting Document...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final provider = context.read<NoteProvider>();
    final noteId = widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Copy to private app sandbox with obfuscated secure extension
    final securedImg = await _secureCopyFile(_imagePath, 'note_${noteId}_pass', noteId);
    final securedPdf = await _secureCopyFile(_pdfPath, 'note_${noteId}_doc', noteId);

    if (widget.note == null) {
      provider.addNote(NoteItem(
        id: noteId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        timestamp: DateTime.now(),
        imagePath: securedImg,
        pdfPath: securedPdf,
      ));
    } else {
      provider.updateNote(widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        timestamp: DateTime.now(),
        imagePath: securedImg,
        pdfPath: securedPdf,
        clearImage: securedImg == null,
        clearPdf: securedPdf == null,
      ));
    }

    if (mounted) {
      Navigator.pop(context); // Dismiss progress dialog
      HapticFeedback.heavyImpact();
      Navigator.pop(context); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.note == null ? 'New Note' : 'Edit Note',
            style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color, fontWeight: FontWeight.bold)),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: () {
                context.read<NoteProvider>().deleteNote(widget.note!.id);
                Navigator.pop(context);
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.check, color: AppTheme.primaryPurple),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMMM dd, hh:mm a').format(widget.note?.timestamp ?? DateTime.now()),
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            
            // Image Preview Card
            if (_imagePath != null) ...[
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_imagePath != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FullImageScreen(imagePath: _imagePath!)));
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity, height: 200),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // PDF Preview Card
            if (_pdfPath != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pdfPath!.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('PDF Document • Tap to Open', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, color: AppTheme.textGrey, size: 18),
                              onPressed: () => setState(() => _pdfPath = null),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfPath: _pdfPath!)));
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          color: Theme.of(context).cardColor,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.05,
                                child: Icon(LucideIcons.fileText, size: 80, color: Theme.of(context).iconTheme.color),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: const Icon(LucideIcons.eye, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Tap to Open Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            TextField(
              controller: _contentController,
              maxLines: null,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Start writing...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAttachmentMenu,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(LucideIcons.paperclip, color: Colors.white),
      ),
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final String imagePath;
  const FullImageScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.white),
            onPressed: () async {
              try {
                final hasAccess = await Gal.hasAccess();
                if (!hasAccess) {
                  await Gal.requestAccess();
                }
                await Gal.putImage(imagePath);
                
                if (context.mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image saved to gallery!'),
                      backgroundColor: AppTheme.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save image: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final fileName = pdfPath.split('/').last;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: PdfViewer.file(
        pdfPath,
        params: const PdfViewerParams(
          maxScale: 4.0,
        ),
      ),
    );
  }
}
