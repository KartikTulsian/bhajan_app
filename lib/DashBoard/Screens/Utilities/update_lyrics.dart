import 'dart:typed_data';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateLyrics extends StatefulWidget {
  final Map<String, dynamic> lyric;

  const UpdateLyrics({super.key, required this.lyric});

  @override
  State<UpdateLyrics> createState() => _UpdateLyricsState();
}

class _UpdateLyricsState extends State<UpdateLyrics> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();
  final _imagePicker = ImagePicker();

  Uint8List? _newImageBytes;
  String? _newImageName;
  bool _isUploading = false;
  late String _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.lyric['lyricsName'] ?? '';
    _currentImageUrl = widget.lyric['lyricsUrl'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
          _newImageName = image.name;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _removeNewImage() {
    setState(() {
      _newImageBytes = null;
      _newImageName = null;
    });
  }

  String _sanitizeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  Future<void> _updateLyrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final title = _titleController.text.trim();
      String finalImageUrl = _currentImageUrl;

      // If new image is selected, upload it
      if (_newImageBytes != null) {
        final sanitizedFileName = _sanitizeFileName(title);
        final fileName = '$sanitizedFileName.jpg';
        finalImageUrl = await _cloudinary.uploadImage(_newImageBytes!, fileName);
      }

      // Update in Supabase
      await _supabase.updateLyric(
        widget.lyric['id'],
        title,
        finalImageUrl,
      );

      _showSnackBar('Lyrics updated successfully!', isError: false);

      // Navigate back after successful update
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      _showSnackBar('Update failed: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteLyrics() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lyrics'),
        content: const Text('Are you sure you want to delete this lyric? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);

    try {
      await _supabase.deleteLyric(widget.lyric['id']);
      _showSnackBar('Lyrics deleted successfully!', isError: false);

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Lyrics'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isUploading ? null : _deleteLyrics,
            tooltip: 'Delete Lyrics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Lyrics Title',
                  hintText: 'Enter the bhajan title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.title, color: Colors.brown),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Current Image Section
              Text(
                'Current Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _currentImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.brown,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // New Image Section
              if (_newImageBytes != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Image (Will replace current)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    IconButton(
                      onPressed: _removeNewImage,
                      icon: Icon(Icons.close, color: Colors.red),
                      tooltip: 'Remove new image',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _newImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $_newImageName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload New Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave empty to keep current image',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Update Button
              ElevatedButton(
                onPressed: _isUploading ? null : _updateLyrics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Updating...'),
                  ],
                )
                    : const Text(
                  'Update Lyrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}