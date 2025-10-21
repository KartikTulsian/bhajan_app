import 'dart:typed_data';
import 'package:bhajan_app/Model/list_builder.dart';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:photo_view/photo_view.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _supabase = SupabaseService();
  final _cloudinary = CloudinaryService();

  // cache box will be opened lazily
  Box<dynamic>? _cacheBox;

  List<Map<String, dynamic>> lyricsList = [];
  List<Map<String, dynamic>> _allLyrics = [];

  bool uploading = false;
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    await _openCacheBoxIfNeeded();
    await fetchLyrics();
  }

  Future<void> _openCacheBoxIfNeeded() async {
    try {
      if (!Hive.isBoxOpen('lyricsCache')) {
        await Hive.openBox('lyricsCache');
      }
      _cacheBox = Hive.box('lyricsCache');
    } catch (e) {
      // If opening fails, keep _cacheBox null and continue — app won't crash.
      debugPrint('Hive openBox error: $e');
      _cacheBox = null;
    }
  }

  Future<void> fetchLyrics() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Attempt network fetch with timeout (prevents hanging)
      final raw = await _supabase
          .fetchLyrics()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        throw Exception('Timeout while fetching lyrics');
      });

      // Ensure we have a safe List<Map<String, dynamic>>
      List<Map<String, dynamic>> fetched = [];
      if (raw is List) {
        try {
          fetched = raw.map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
        } catch (_) {
          fetched = List<Map<String, dynamic>>.from(raw);
        }
      }

      // Sort alphabetically
      fetched.sort((a, b) => a['lyricsName']
          .toString()
          .toLowerCase()
          .compareTo(b['lyricsName'].toString().toLowerCase()));

      _allLyrics = fetched;
      if (mounted) setState(() => lyricsList = List<Map<String, dynamic>>.from(_allLyrics));

      // Save to cache if box available
      try {
        _cacheBox?.put('lyrics', _allLyrics);
      } catch (e) {
        debugPrint('Cache put error: $e');
      }
    } catch (e) {
      debugPrint('fetchLyrics error: $e — falling back to cache');
      // Fallback to cache
      try {
        final cached = _cacheBox?.get('lyrics', defaultValue: []);
        if (cached is List && cached.isNotEmpty) {
          _allLyrics = List<Map<String, dynamic>>.from(cached);
        } else {
          _allLyrics = [];
        }
      } catch (e2) {
        debugPrint('Cache read error: $e2');
        _allLyrics = [];
      }

      if (mounted) setState(() => lyricsList = List<Map<String, dynamic>>.from(_allLyrics));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> uploadLyrics() async {
    if (!mounted) return;
    setState(() => uploading = true);

    for (final lyric in lyrics) {
      final name = lyric.lyricsName;
      final path = lyric.lyricsPath;
      final fileName = path.split('/').last;

      try {
        ByteData data = await rootBundle.load(path);
        Uint8List bytes = data.buffer.asUint8List();

        final url = await _cloudinary.uploadImage(bytes, fileName);

        final existing = await _supabase.fetchLyrics();

        if (!existing.any((e) => e['lyricsName'] == name)) {
          await _supabase.addLyric(name, url);
          debugPrint('✅ Uploaded: $name');
        } else {
          debugPrint('⚠️ Skipped duplicate: $name');
        }
      } catch (e) {
        debugPrint('❌ Error uploading $path: $e');
      }
    }

    await fetchLyrics();
    if (mounted) setState(() => uploading = false);
  }

  void filterLyrics(String query) {
    final trimmed = query.trim();
    if (!mounted) return;
    setState(() => _searchQuery = trimmed);

    if (trimmed.isEmpty) {
      // show full list from memory (no network refetch)
      setState(() => lyricsList = List<Map<String, dynamic>>.from(_allLyrics));
      return;
    }

    final lowerQuery = trimmed.toLowerCase();
    final queryWords =
    lowerQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final filtered = _allLyrics.where((lyric) {
      final title = (lyric['lyricsName'] ?? '').toString().toLowerCase();
      // require every query word to appear somewhere in title
      return queryWords.every((word) => title.contains(word));
    }).toList();

    // Put prefix matches first
    filtered.sort((a, b) {
      final aTitle = (a['lyricsName'] ?? '').toString().toLowerCase();
      final bTitle = (b['lyricsName'] ?? '').toString().toLowerCase();
      final aStarts = aTitle.startsWith(lowerQuery) ? 0 : 1;
      final bStarts = bTitle.startsWith(lowerQuery) ? 0 : 1;
      return aStarts.compareTo(bStarts);
    });

    setState(() => lyricsList = filtered);
  }

  Widget _highlightMatch(String source, String query) {
    if (query.isEmpty) {
      return Text(
        source,
        style: TextStyle(
          color: Colors.brown.shade900,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      );
    }

    final lowerSource = source.toLowerCase();
    final queryWords =
    query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final spans = <TextSpan>[];

    int start = 0;
    while (start < source.length) {
      int closestIndex = source.length;
      String? closestWord;

      for (final word in queryWords) {
        final index = lowerSource.indexOf(word, start);
        if (index >= 0 && index < closestIndex) {
          closestIndex = index;
          closestWord = word;
        }
      }

      if (closestIndex == source.length) {
        spans.add(TextSpan(
          text: source.substring(start),
          style: TextStyle(
            color: Colors.brown.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ));
        break;
      }

      if (closestIndex > start) {
        spans.add(TextSpan(
          text: source.substring(start, closestIndex),
          style: TextStyle(
            color: Colors.brown.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ));
      }

      spans.add(TextSpan(
        text: source.substring(closestIndex, closestIndex + closestWord!.length),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ));

      start = closestIndex + closestWord.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sadhna Path Book'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : fetchLyrics,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/gosaijiblurback2.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Column(
          children: [
            Image.asset('assets/images/naambrahmanew.png'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.brown.shade200),
                ),
                child: TextField(
                  onChanged: filterLyrics,
                  decoration: const InputDecoration(
                    hintText: 'Search Bhajan...',
                    prefixIcon: Icon(Icons.search, color: Colors.brown),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: TextStyle(
                      color: Colors.brown.shade900,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.brown,
                  strokeWidth: 3,
                ),
              )
                  : (lyricsList.isEmpty
                  ? Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No Bhajan Available'
                      : 'No Bhajan Found',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.brown.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: lyricsList.length,
                itemBuilder: (context, index) {
                  final lyric = lyricsList[index];
                  final title = lyric['lyricsName']?.toString() ?? '';
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerPage(
                            imageUrl: lyric['lyricsUrl']?.toString() ?? '',
                            bhajanName: title,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 5,
                      shadowColor: Colors.brown.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 17,
                        ),
                        child: _highlightMatch(title, _searchQuery),
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageViewerPage extends StatelessWidget {
  final String imageUrl;
  final String bhajanName;

  const ImageViewerPage({
    required this.imageUrl,
    required this.bhajanName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bhajanName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          top: false, // ✅ don't add top padding
          left: false,
          right: false,
          bottom: true, // ✅ only protect bottom area
          child: Column(
            children: [
              Image.asset('assets/images/naambrahmanew.png'),
              Expanded(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration:
                  const BoxDecoration(color: Colors.white),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  initialScale: PhotoViewComputedScale.contained,
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8),
              //   child: Image.asset('assets/images/naambrahmanew.png'),
              // ),
              SafeArea(
                top: false,
                left: false,
                right: false,
                child: Image.asset('assets/images/naambrahmanew.png'),
              )
            ],
          ),
        ),
      ),
    );
  }
}