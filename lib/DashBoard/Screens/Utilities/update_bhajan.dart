import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';

class UpdateBhajan extends StatefulWidget {
  final Map<String, dynamic> bhajan;

  const UpdateBhajan({super.key, required this.bhajan});

  @override
  State<UpdateBhajan> createState() => _UpdateBhajanState();
}

class _UpdateBhajanState extends State<UpdateBhajan> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customArtistController = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();

  Uint8List? _selectedAudioBytes;
  String? _selectedAudioName;
  bool _isUpdating = false;

  String? _selectedArtist;
  String? _selectedCategory;
  String? _selectedTimeCategory;

  String _originalTitle = '';
  String _originalCategory = '';
  String _currentAudioUrl = '';

  final List<String> _artists = [
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

  final List<Map<String, String>> _timeCategories = [
    {'value': 'morning', 'label': 'Morning Playlist'},
    {'value': 'evening', 'label': 'Evening Playlist'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBhajanData();
  }

  Future<void> _loadBhajanData() async {
    _originalTitle = widget.bhajan['bhajan_name'] ?? '';
    _originalCategory = widget.bhajan['category'] ?? '';
    _currentAudioUrl = widget.bhajan['audio_url'] ?? '';

    _titleController.text = _originalTitle;

    final artist = widget.bhajan['artist_name'] ?? '';
    _selectedArtist = _artists.contains(artist) ? artist : 'Other';
    if (_selectedArtist == 'Other') {
      _customArtistController.text = artist;
    }

    // Set main category (not morning/evening)
    if (_originalCategory == 'morning' || _originalCategory == 'evening') {
      _selectedTimeCategory = _originalCategory;
      // Try to find the main category from database
      await _findMainCategory();
    } else {
      _selectedCategory = _originalCategory;
      // Check if there's a time category version
      await _findTimeCategory();
    }

    setState(() {});
  }

  Future<void> _findMainCategory() async {
    // Find the main category row for this bhajan
    try {
      final rows = await _supabase.fetchBhajansByName(_originalTitle);
      for (var row in rows) {
        String cat = row['category'] ?? '';
        if (cat != 'morning' && cat != 'evening') {
          _selectedCategory ??= cat;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error finding main category: $e');
    }
  }

  Future<void> _findTimeCategory() async {
    // Check if there's a morning/evening version
    try {
      final rows = await _supabase.fetchBhajansByName(_originalTitle);
      for (var row in rows) {
        String cat = row['category'] ?? '';
        if (cat == 'morning' || cat == 'evening') {
          _selectedTimeCategory ??= cat;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error finding time category: $e');
    }
  }

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
      }
    } catch (e) {
      _showSnackBar('Error picking audio: $e', isError: true);
    }
  }

  void _removeNewAudio() {
    setState(() {
      _selectedAudioBytes = null;
      _selectedAudioName = null;
    });
  }

  String _sanitizeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  Future<void> _updateBhajan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    if (_selectedArtist == null) {
      _showSnackBar('Please select an artist', isError: true);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final newTitle = _titleController.text.trim();
      final artist = _selectedArtist == 'Other'
          ? _customArtistController.text.trim()
          : _selectedArtist!;
      String audioUrl = _currentAudioUrl;

      // Upload new audio if selected
      if (_selectedAudioBytes != null) {
        final sanitizedFileName = _sanitizeFileName(newTitle);
        final fileName = '$sanitizedFileName.mp3';
        audioUrl = await _cloudinary.uploadAudio(_selectedAudioBytes!, fileName);
      }

      // Update strategy:
      // 1. Delete all old rows with the original title
      // 2. Create new rows with updated data

      await _supabase.deleteBhajansByName(_originalTitle);

      // Add main category bhajan
      await _supabase.addBhajan(newTitle, artist, _selectedCategory!, audioUrl);

      // Add time category if selected
      if (_selectedTimeCategory != null) {
        await _supabase.addBhajan(newTitle, artist, _selectedTimeCategory!, audioUrl);
      }

      _showSnackBar('Bhajan updated successfully!', isError: false);

      // Navigate back
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      _showSnackBar('Update failed: $e', isError: true);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteBhajan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bhajan'),
        content: const Text('Are you sure you want to delete this bhajan? This action cannot be undone.'),
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

    setState(() => _isUpdating = true);

    try {
      await _supabase.deleteBhajan(widget.bhajan['id']);
      _showSnackBar('Bhajan deleted successfully!', isError: false);

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
      setState(() => _isUpdating = false);
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
        title: const Text('Update Bhajan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isUpdating ? null : _deleteBhajan,
            tooltip: 'Delete Bhajan',
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
                  return DropdownMenuItem(
                    value: artist,
                    child: Text(artist),
                  );
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

              // Custom Artist Input
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

              // Main Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Main Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.category, color: Colors.brown),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                      value: c['value'], child: Text(c['label']!));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),

              const SizedBox(height: 16),

              // Time Category (morning/evening)
              DropdownButtonFormField<String>(
                value: _selectedTimeCategory,
                decoration: InputDecoration(
                  labelText: 'Time Category (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.schedule, color: Colors.brown),
                ),
                items: _timeCategories.map((c) {
                  return DropdownMenuItem(
                      value: c['value'], child: Text(c['label']!));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTimeCategory = value),
              ),

              const SizedBox(height: 24),

              // Current Audio Info
              Text(
                'Current Audio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  border: Border.all(color: Colors.brown.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.audio_file, size: 32, color: Colors.brown.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentAudioUrl.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // New Audio Section
              if (_selectedAudioBytes != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Audio (Will replace current)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    IconButton(
                      onPressed: _removeNewAudio,
                      icon: Icon(Icons.close, color: Colors.red),
                      tooltip: 'Remove new audio',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.audio_file, size: 48, color: Colors.green.shade700),
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
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _pickAudio,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload New Audio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave empty to keep current audio',
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
                onPressed: _isUpdating ? null : _updateBhajan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdating
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
                  'Update Bhajan',
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