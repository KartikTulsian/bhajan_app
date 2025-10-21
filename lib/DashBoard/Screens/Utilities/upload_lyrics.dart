import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';

class UploadLyrics extends StatefulWidget {
  const UploadLyrics({super.key});

  @override
  State<UploadLyrics> createState() => _UploadLyricsState();
}

class _UploadLyricsState extends State<UploadLyrics> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();
  final _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

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
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  String _sanitizeFileName(String title) {
    // Convert to lowercase and remove special characters
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  Future<void> _uploadLyrics() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageBytes == null) {
      _showSnackBar('Please select an image', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final title = _titleController.text.trim();
      final sanitizedFileName = _sanitizeFileName(title);
      final fileName = '$sanitizedFileName.jpg';

      // Upload to Cloudinary
      final imageUrl = await _cloudinary.uploadImage(_selectedImageBytes!, fileName);

      // Store in Supabase
      await _supabase.addLyric(title, imageUrl);

      _showSnackBar('Lyrics uploaded successfully!', isError: false);

      // Clear form
      _titleController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      // Navigate back after successful upload
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
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
        title: const Text('Upload Lyrics'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
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

              // Image Preview or Pick Button
              if (_selectedImageBytes != null) ...[
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedImageName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.change_circle),
                  label: const Text('Change Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: _isUploading ? null : _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      border: Border.all(
                        color: Colors.brown.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: Colors.brown.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to Select Image',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'JPG, PNG (max 10MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Upload Button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadLyrics,
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
                    const Text('Uploading...'),
                  ],
                )
                    : const Text(
                  'Upload Lyrics',
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