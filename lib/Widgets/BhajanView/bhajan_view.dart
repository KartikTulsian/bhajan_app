//import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:bhajan_app/main.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:audioplayers/audioplayers.dart';
import 'package:bhajan_app/service/cloudinary_service.dart';
import 'package:bhajan_app/service/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:bhajan_app/Model/bhajan_audio_player_model.dart';
import 'package:bhajan_app/Model/list_builder.dart';
import 'package:bhajan_app/Model/list_item.dart';
import 'package:permission_handler/permission_handler.dart';

class BhajanView extends StatefulWidget {
  const BhajanView({super.key});

  @override
  _BhajanViewState createState() => _BhajanViewState();
}

class _BhajanViewState extends State<BhajanView> {
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();

  Box<dynamic>? _cacheBox;

  bool uploading = false;
  bool isLoading = true;
  String _searchQuery = '';

  StreamSubscription<void>? _completionSubscription;

  Future<void> uploadAllBhajans() async {
    setState(() => uploading = true);

    // combine all categories
    final allCategories = {
      'hindi': hindi,
      'bangla': bangla,
      'morning': morning,
      'evening': evening,
      'sankirtan': sankirtan,
      'rags111': rags111,
      'harekrishna': harekrishna,
      'shriram': shriram,
      'jagannath': jagannath,
      'thakur': thakur,
      'bade': bade,
      'mejo': mejo,
      'dada': dada,
      'path': path,
    };
    for (final entry in allCategories.entries) {
      final category = entry.key;
      final items = entry.value;

      for (final item in items) {
        try {
          final response = await http.get(Uri.parse(item.url));
          if (response.statusCode != 200) {
            debugPrint('❌ Failed to download: ${item.bhajanName}');
            continue;
          }

          final bytes = response.bodyBytes;
          final safeName = item.bhajanName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
          final fileName = '$safeName.mp3';


          // Upload to Cloudinary
          final cloudUrl = await _cloudinary.uploadAudio(bytes, fileName);

          // Store in Supabase
          await _supabase.addBhajan(
            item.bhajanName,
            item.artistName,
            category,
            cloudUrl,
          );

          debugPrint('✅ Uploaded: ${item.bhajanName}');
        } catch (e) {
          debugPrint('⚠️ Error uploading ${item.bhajanName}: $e');
        }
      }
    }

    setState(() => uploading = false);
    debugPrint('🎵 All bhajans uploaded successfully!');
  }

  String bhajanName = ' ';
  String link = '';

  Map<String, List<Item>> categoryBhajans = {
    'hindi': [],
    'bangla': [],
    'morning': [],
    'evening': [],
    'sankirtan': [],
    'rags111': [],
    'harekrishna': [],
    'shriram': [],
    'jagannath': [],
    'thakur': [],
    'bade': [],
    'mejo': [],
    'dada': [],
    'path': [],
  };

  Map<String, List<Item>> filteredCategoryBhajans = {
    'hindi': [],
    'bangla': [],
    'morning': [],
    'evening': [],
    'sankirtan': [],
    'rags111': [],
    'harekrishna': [],
    'shriram': [],
    'jagannath': [],
    'thakur': [],
    'bade': [],
    'mejo': [],
    'dada': [],
    'path': [],
  };

  int selectedIconIndex = 0;
  int selectedIndex = -10;

  TextEditingController textFieldController = TextEditingController();

  final List<String> iconLabels = [
    'Hindi\nBhajans',
    'Bangla\nBhajans',
    'Morning\nPlaylist',
    'Evening\nPlaylist',
    'Bhajo Guru\nChorus',
    'Bhajo Guru\nin 111 Rags',
    'Shri Ram\nJai Ram',
    'Hare Krishna\nHare Rama',
    'Jai Jagannath\nSankirtan',
    'By Swami\nAsimananda\nSaraswati Ji',
    'By Swami\nAlokananda\nSaraswati Ji',
    'By Swami\nAmalananda\nSaraswati Ji',
    'By Shri Amit\nBrahmachari\nJi',
    'Path and\nPravachans',
  ];

  List<String> iconImages = [
    "assets/images/omhindi2.png",
    "assets/images/ombengali.png",
    "assets/images/morning.jpg",
    "assets/images/evening.jpg",
    "assets/images/gosaiji2.png",
    "assets/images/shridarveshji.jpg",
    "assets/images/shriram.jpg",
    "assets/images/shrikrishna.jpg",
    "assets/images/puridham.jpg",
    "assets/images/shrithakur.png",
    "assets/images/badesadhubaba.png",
    "assets/images/mejosadhubaba.png",
    "assets/images/shridada.png",
    "assets/images/shridada.png",
    // Add more asset paths for each item in the ListView
  ];

  final List<String> categoryKeys = [
    'hindi',
    'bangla',
    'morning',
    'evening',
    'sankirtan',
    'rags111',
    'shriram',
    'harekrishna',
    'jagannath',
    'thakur',
    'bade',
    'mejo',
    'dada',
    'path',
  ];

  @override
  void initState() {
    super.initState();
    _initAndFetch();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    // Request POST_NOTIFICATIONS permission required for Android 13+
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initAndFetch() async {
    await _openCacheBoxIfNeeded();
    await fetchBhajans();
  }

  Future<void> _openCacheBoxIfNeeded() async {
    try {
      if (!Hive.isBoxOpen('bhajansCache')) {
        await Hive.openBox('bhajansCache');
      }
      _cacheBox = Hive.box('bhajansCache');
    } catch (e) {
      debugPrint('Hive openBox error: $e');
      _cacheBox = null;
    }
  }

  Future<void> fetchBhajans() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Fetch from Supabase
      final raw = await _supabase
          .fetchBhajans()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Timeout while fetching bhajans');
      });

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

      // Group by category
      for (var category in categoryBhajans.keys) {
        categoryBhajans[category] = [];
      }

      int identifier = 0;
      for (var bhajan in fetched) {
        String category = bhajan['category']?.toString() ?? '';
        String artistName = bhajan['artist_name']?.toString() ?? '';

        if (categoryBhajans.containsKey(category)) {
          final item = Item(
            identifier: identifier++,
            bhajanName: bhajan['bhajan_name']?.toString() ?? '',
            artistName: artistName,
            url: bhajan['audio_url']?.toString() ?? '',
          );

          categoryBhajans[category]!.add(item);

          // Add to special artist categories from ALL categories except thakur and path
          if (category != 'thakur' && category != 'path' && category != 'morning' && category != 'evening') {
            if (artistName == 'Shrimat Amit Brahmachari') {
              categoryBhajans['dada']!.add(item);
            } else if (artistName == 'Swami Alokananda Saraswati') {
              categoryBhajans['bade']!.add(item);
            } else if (artistName == 'Swami Amalananda Saraswati') {
              categoryBhajans['mejo']!.add(item);
            }
          }
        }
      }

      categoryBhajans.forEach((key, value) {
        value.sort((a, b) => a.bhajanName
            .toLowerCase()
            .compareTo(b.bhajanName.toLowerCase()));
      });

      // Initialize filtered lists
      resetFilteredLists();

      // Save to cache
      try {
        Map<String, dynamic> cacheData = {};
        categoryBhajans.forEach((key, value) {
          cacheData[key] = value.map((item) => {
            'identifier': item.identifier,
            'bhajanName': item.bhajanName,
            'artistName': item.artistName,
            'url': item.url,
          }).toList();
        });
        _cacheBox?.put('bhajans', cacheData);
      } catch (e) {
        debugPrint('Cache put error: $e');
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('fetchBhajans error: $e — falling back to cache');

      // Fallback to cache
      try {
        final cached = _cacheBox?.get('bhajans');
        if (cached is Map) {
          int identifier = 0;
          cached.forEach((key, value) {
            if (value is List && categoryBhajans.containsKey(key)) {
              categoryBhajans[key] = value.map((item) {
                return Item(
                  identifier: identifier++,
                  bhajanName: item['bhajanName']?.toString() ?? '',
                  artistName: item['artistName']?.toString() ?? '',
                  url: item['url']?.toString() ?? '',
                );
              }).toList();
            }
          });

          categoryBhajans.forEach((key, value) {
            value.sort((a, b) => a.bhajanName
                .toLowerCase()
                .compareTo(b.bhajanName.toLowerCase()));
          });

          resetFilteredLists();
        }
      } catch (e2) {
        debugPrint('Cache read error: $e2');
      }

      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void resetFilteredLists() {
    categoryBhajans.forEach((key, value) {
      filteredCategoryBhajans[key] = List<Item>.from(value);
    });
  }

  void resetSearch() {
    textFieldController.clear();
    _searchQuery = '';
    resetFilteredLists();
    setState(() {});
  }

  void filterBhajan(String query) {
    String currentCategory = categoryKeys[selectedIconIndex];
    final trimmed = query.trim();

    if (!mounted) return;
    setState(() => _searchQuery = trimmed);

    if (trimmed.isEmpty) {
      filteredCategoryBhajans[currentCategory] = List<Item>.from(categoryBhajans[currentCategory]!);
      setState(() {});
      return;
    }

    final lowerQuery = trimmed.toLowerCase();
    final queryWords = lowerQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final filtered = categoryBhajans[currentCategory]!.where((item) {
      final title = item.bhajanName.toLowerCase();
      return queryWords.every((word) => title.contains(word));
    }).toList();

    filtered.sort((a, b) {
      final aTitle = a.bhajanName.toLowerCase();
      final bTitle = b.bhajanName.toLowerCase();
      final aStarts = aTitle.startsWith(lowerQuery) ? 0 : 1;
      final bStarts = bTitle.startsWith(lowerQuery) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      return aTitle.compareTo(bTitle);
    });

    filteredCategoryBhajans[currentCategory] = filtered;
    setState(() {});
  }

  Widget _highlightMatch(String source, String query) {
    if (query.isEmpty) {
      return Text(
        source,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      );
    }

    final lowerSource = source.toLowerCase();
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 18,
          ),
        ));
        break;
      }

      if (closestIndex > start) {
        spans.add(TextSpan(
          text: source.substring(start, closestIndex),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 18,
          ),
        ));
      }

      spans.add(TextSpan(
        text: source.substring(closestIndex, closestIndex + closestWord!.length),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ));

      start = closestIndex + closestWord.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  void dispose() {
    textFieldController.dispose();
    _completionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhajans'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : fetchBhajans,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/gosaijiblurback2.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 100,
              color: const Color.fromARGB(62, 227, 202, 182),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: iconLabels.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIconIndex = index;
                          selectedIndex = -10;
                          resetSearch();
                        });
                      },
                      child: SizedBox(
                          width: 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  iconImages[index],
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              //SizedBox(height: 9),
                              Text(
                                iconLabels[index],
                                style: TextStyle(
                                  color: selectedIconIndex == index
                                      ? Colors.brown.shade500
                                      : Colors.brown.shade200,
                                  fontSize:
                                  selectedIconIndex == index ? 9.0 : 9.0,
                                  fontWeight: selectedIconIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                //maxLines: 2,
                              ),
                            ],
                          )),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: textFieldController,
                  onChanged: filterBhajan,
                  decoration: InputDecoration(
                    labelText: 'Search Bhajan',
                    labelStyle: TextStyle(color: Colors.brown),
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.brown),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.brown), // Border when not focused
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.brown,
                          width: 2.0), // Border when focused
                    ),
                  ),
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
                  : _buildBhajanList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBhajanList() {
    String currentCategory = categoryKeys[selectedIconIndex];
    List<Item> currentList = filteredCategoryBhajans[currentCategory] ?? [];

    if (currentList.isEmpty) {
      return Center(
        child: Text(
          textFieldController.text.isEmpty
              ? 'No Bhajans Available'
              : 'No Bhajans Found',
          style: TextStyle(
            fontSize: 20,
            color: Colors.brown.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      itemCount: currentList.length,
      separatorBuilder: (context, index) {
        return Divider(
          color: Colors.brown.shade100,
          thickness: 0.4,
          height: 1,
        );
      },
      itemBuilder: (context, index) {
        Item item = currentList[index];
        bool isSelected = selectedIndex == index;

        return ListTile(
          title: isSelected
              ? Text(
            item.bhajanName,
            style: TextStyle(
              color: Colors.brown.shade800,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          )
              : _highlightMatch(item.bhajanName, _searchQuery),
          subtitle: Text(
            item.artistName,
            style: TextStyle(
              color: isSelected ? Colors.brown.shade800 : Colors.black,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          onTap: () {
            setState(() => selectedIndex = index);
            _playMusic(
              item.bhajanName,
              index,
              item.url,
              selectedIconIndex,
            );
          },
        );
      },
    );
  }

  void _playMusic( String songName, int listIndex, String url, int iconIndex) async {
    _completionSubscription?.cancel();

    await playerData.player.stop();
    await playerData.player.release();

    Source audioUrl = UrlSource(url);

    print('Playing bhajan index: $listIndex and icon: $iconIndex');
    print('Playing bhajan with URL: $url');

    await playerData.player.play(audioUrl);

    // Set media item for notification
    String currentCategory = categoryKeys[iconIndex];
    String artistName = categoryBhajans[currentCategory]?[listIndex].artistName ?? '';

    final displayTitle = '$songName - Sadhna Path';
    audioHandler.setMediaItem(displayTitle, artistName, url);

    // audioHandler.setMediaItem(songName, artistName, url);

    // Set callbacks for next/previous in notification
    audioHandler.onSkipToNext = () => playNextSong(listIndex, iconIndex);
    audioHandler.onSkipToPrevious = () => playPreviousSong(listIndex, iconIndex);

    // Handle auto-play next on completion
    _completionSubscription = playerData.player.onPlayerComplete.listen((event) {
      playNextSong(listIndex, iconIndex);
    });

    setState(() {
      playerData.bhajanName = songName;
      playerData.isPlaying = true;
      playerData.selectedList = getSongList(iconIndex);
      playerData.currentIndex = listIndex;
      selectedIndex = listIndex;
    });

    print('bhajan played');
  }

  void playPreviousSong(int currentListIndex, int iconIndex) {
    String currentCategory = categoryKeys[iconIndex];
    List<Item> currentList = categoryBhajans[currentCategory] ?? [];

    if (currentList.isEmpty) return;

    int prevIndex = (currentListIndex - 1 < 0)
        ? currentList.length - 1
        : currentListIndex - 1;
    Item prevSong = currentList[prevIndex];

    setState(() => selectedIndex = prevIndex);
    _playMusic(prevSong.bhajanName, prevIndex, prevSong.url, iconIndex);
  }

  List<Item> getSongList(int index) {
    if (index >= 0 && index < categoryKeys.length) {
      return categoryBhajans[categoryKeys[index]] ?? [];
    }
    return [];
  }

  void playNextSong(int currentListIndex, int iconIndex) {
    String currentCategory = categoryKeys[iconIndex];
    List<Item> currentList = categoryBhajans[currentCategory] ?? [];

    if (currentList.isEmpty) return;

    int nextIndex = (currentListIndex + 1) % currentList.length;
    Item nextSong = currentList[nextIndex];

    setState(() {
      selectedIndex = nextIndex;
    });

    _playMusic(nextSong.bhajanName, nextIndex, nextSong.url, iconIndex);
  }

// void _pauseMusic() {
//   audioPlayer.pause();
//   setState(() {
//     isPlaying = false;
//   });
// }

// void _resumeMusic() {
//   audioPlayer.resume();
//   setState(() {
//     isPlaying = true;
//   });
// }

// void _seekBy(int seconds) {
//   int currentPosition = currentDuration.toInt();
//   int newPosition = currentPosition + (seconds * 1000);

//   if (newPosition < 0) {
//     newPosition = 0;
//   } else if (newPosition > audioDuration) {
//     newPosition = audioDuration.toInt();
//   }

//   setState(() {
//     currentDuration = newPosition.toDouble();
//   });

//   audioPlayer.seek(Duration(milliseconds: newPosition));
// }

// String formatDurationInMmSs(Duration duration) {
//   final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
//   final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
//   return '$mm:$ss';
// }
}
