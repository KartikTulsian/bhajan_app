import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';

class UploadBhajan extends StatefulWidget {
  const UploadBhajan({super.key});

  @override
  State<UploadBhajan> createState() => _UploadBhajanState();
}

class _UploadBhajanState extends State<UploadBhajan> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customArtistController = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();

  Uint8List? _selectedAudioBytes;
  String? _selectedAudioName;
  bool _isUploading = false;

  String? _selectedArtist;
  String? _selectedCategory;

  final List<String> _artists = [
    'Select Artist Name',
    'Shrimat Amit Brahmachari',
    'Swami Alokananda Saraswati',
    'Swami Amalananda Saraswati',
    'Swami Asimananda Saraswati',
    'Mata Shailbaba Devi',
    'Other',
  ];

  final List<Map<String, String>> _categories = [
    {'value': 'hindi', 'label': 'Hindi Bhajans'},
    {'value': 'bangla', 'label': 'Bangla Bhajans'},
    {'value': 'sankirtan', 'label': 'Bhajo Guru Chorus'},
    {'value': 'rags111', 'label': 'Bhajo Guru in 111 Rags'},
    {'value': 'harekrishna', 'label': 'Hare Krishna Hare Rama'},
    {'value': 'shriram', 'label': 'Shri Ram Jai Ram'},
    {'value': 'jagannath', 'label': 'Jai Jagannath Sankirtan'},
    {'value': 'thakur', 'label': 'By Swami Asimananda Saraswati Ji'},
    {'value': 'path', 'label': 'Path and Pravachans'},
  ];

  String? _selectedTimeCategory;

  final List<Map<String, String>> _timeCategories = [
    {'value': 'morning', 'label': 'Morning Playlist'},
    {'value': 'evening', 'label': 'Evening Playlist'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _customArtistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedAudioBytes = file.bytes;
          _selectedAudioName = file.name;
        });

        if (_selectedAudioBytes != null) {
          _showSnackBar('Audio file selected: ${file.name}', isError: false);
        } else {
          _showSnackBar('Failed to load audio file', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error picking audio: $e', isError: true);
    }
  }

  String _sanitizeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  Future<void> _uploadBhajan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudioBytes == null) {
      _showSnackBar('Please select an audio file', isError: true);
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    if (_selectedArtist == null) {
      _showSnackBar('Please select an artist', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final title = _titleController.text.trim();
      final artist = _selectedArtist == 'Other'
          ? _customArtistController.text.trim()
          : _selectedArtist!;

      final sanitizedFileName = _sanitizeFileName(title);
      final fileName = '$sanitizedFileName.mp3';

      // Upload to Cloudinary
      final audioUrl = await _cloudinary.uploadAudio(
        _selectedAudioBytes!,
        fileName,
      );

      // Store main bhajan
      await _supabase.addBhajan(title, artist, _selectedCategory!, audioUrl);

      // Also store the morning/evening version (same URL)
      if (_selectedTimeCategory != null) {
        await _supabase.addBhajan(
          title,
          artist,
          _selectedTimeCategory!,
          audioUrl,
        );
      }

      _showSnackBar('Bhajan uploaded successfully!', isError: false);

      // Clear form
      _titleController.clear();
      _customArtistController.clear();
      setState(() {
        _selectedAudioBytes = null;
        _selectedAudioName = null;
        _selectedArtist = null;
        _selectedCategory = null;
        _selectedTimeCategory = null;
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
        title: const Text('Upload Bhajan'),
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
                  labelText: 'Bhajan Title',
                  hintText: 'Enter the bhajan title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.music_note, color: Colors.brown),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Artist Dropdown
              DropdownButtonFormField<String>(
                value: _selectedArtist,
                decoration: InputDecoration(
                  labelText: 'Artist Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.brown),
                ),
                items: _artists.map((artist) {
                  return DropdownMenuItem(value: artist, child: Text(artist));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArtist = value;
                    if (value != 'Other') {
                      _customArtistController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an artist';
                  }
                  return null;
                },
              ),

              // Custom Artist Input (shown when "Other" is selected)
              if (_selectedArtist == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customArtistController,
                  decoration: InputDecoration(
                    labelText: 'Enter Artist Name',
                    hintText: 'Type custom artist name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.edit, color: Colors.brown),
                  ),
                  validator: (value) {
                    if (_selectedArtist == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter artist name';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.category, color: Colors.brown),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category['value'],
                    child: Text(category['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Morning/Evening Dropdown
              DropdownButtonFormField<String>(
                value: _selectedTimeCategory,
                decoration: InputDecoration(
                  labelText: 'Time of Bhajan (Optional: Morning / Evening)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.wb_sunny, color: Colors.brown),
                ),
                items: _timeCategories.map((category) {
                  return DropdownMenuItem(
                    value: category['value'],
                    child: Text(category['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTimeCategory = value);
                },
              ),

              const SizedBox(height: 24),

              // Audio File Picker
              if (_selectedAudioBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.audio_file,
                        size: 48,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected Audio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAudioName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAudio,
                  icon: const Icon(Icons.change_circle),
                  label: const Text('Change Audio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: _isUploading ? null : _pickAudio,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 150,
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
                          Icons.audiotrack,
                          size: 64,
                          color: Colors.brown.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to Select Audio File',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MP3, WAV, M4A (max 50MB)',
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
                onPressed: _isUploading ? null : _uploadBhajan,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Uploading...'),
                        ],
                      )
                    : const Text(
                        'Upload Bhajan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
