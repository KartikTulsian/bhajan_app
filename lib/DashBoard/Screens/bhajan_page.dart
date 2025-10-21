import 'dart:typed_data';
import 'package:bhajan_app/DashBoard/Screens/Utilities/upload_bhajan.dart';
import 'package:bhajan_app/DashBoard/Screens/Utilities/update_bhajan.dart';
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

class BhajanPage extends StatefulWidget {
  const BhajanPage({super.key});

  @override
  State<BhajanPage> createState() => _BhajanPageState();
}

class _BhajanPageState extends State<BhajanPage> {
  final _cloudinary = CloudinaryService();
  final _supabase = SupabaseService();

  Box<dynamic>? _cacheBox;

  bool uploading = false;
  bool isLoading = true;
  String _searchQuery = '';

  // Store original bhajans with IDs for editing/deleting
  List<Map<String, dynamic>> _allBhajansRaw = [];

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

      // Store raw data for edit/delete
      _allBhajansRaw = List<Map<String, dynamic>>.from(fetched);

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

      // Sort each category alphabetically
      categoryBhajans.forEach((key, value) {
        value.sort((a, b) => a.bhajanName
            .toLowerCase()
            .compareTo(b.bhajanName.toLowerCase()));
      });

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
      filteredCategoryBhajans[currentCategory] =
      List<Item>.from(categoryBhajans[currentCategory]!);
      setState(() {});
      return;
    }

    final lowerQuery = trimmed.toLowerCase();
    final queryWords =
    lowerQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

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

  Map<String, dynamic>? _getBhajanData(Item item) {
    return _allBhajansRaw.firstWhere(
          (bhajan) =>
      bhajan['bhajan_name'] == item.bhajanName &&
          bhajan['artist_name'] == item.artistName,
      orElse: () => {},
    );
  }

  Future<void> _navigateToUpdate(Item item) async {
    final bhajanData = _getBhajanData(item);
    if (bhajanData == null || bhajanData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bhajan data not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateBhajan(bhajan: bhajanData),
      ),
    );

    if (result == true) {
      fetchBhajans();
    }
  }

  Future<void> _deleteBhajan(Item item) async {
    final bhajanData = _getBhajanData(item);
    if (bhajanData == null || bhajanData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bhajan data not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bhajan'),
        content: Text('Are you sure you want to delete "${item.bhajanName}"?'),
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

    try {
      await _supabase.deleteBhajan(bhajanData['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bhajan deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      fetchBhajans();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhajans'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : fetchBhajans,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadBhajan()),
          );
          if (result == true) {
            fetchBhajans();
          }
        },
        label: Text("Upload Bhajan"),
        icon: Icon(Icons.cloud_upload),
        heroTag: "uploadBhajan",
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
                            Text(
                              iconLabels[index],
                              style: TextStyle(
                                color: selectedIconIndex == index
                                    ? Colors.brown.shade500
                                    : Colors.brown.shade200,
                                fontSize: 9.0,
                                fontWeight: selectedIconIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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
                      borderSide: BorderSide(color: Colors.brown),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.brown, width: 2.0),
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
          _searchQuery.isEmpty ? 'No Bhajans Available' : 'No Bhajans Found',
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
          title: Row(
            children: [
              Expanded(
                child: isSelected
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
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    onPressed: () => _navigateToUpdate(item),
                    tooltip: 'Edit',
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                    onPressed: () => _deleteBhajan(item),
                    tooltip: 'Delete',
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
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

  void _playMusic(String songName, int listIndex, String url, int iconIndex) async {
    await playerData.player.stop();
    await playerData.player.release();

    Source audioUrl = UrlSource(url);

    print('Playing bhajan index: $listIndex and icon: $iconIndex');
    print('Playing bhajan with URL: $url');

    await playerData.player.play(audioUrl);

    audioHandler.setMediaItem(
        songName, categoryBhajans[categoryKeys[iconIndex]]?[listIndex].artistName ?? '', url);

    audioHandler.onSkipToNext = () => playNextSong(listIndex, iconIndex);
    audioHandler.onSkipToPrevious = () => playPreviousSong(listIndex, iconIndex);

    playerData.player.onPlayerComplete.listen((event) {
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

    int prevIndex =
    (currentListIndex - 1 < 0) ? currentList.length - 1 : currentListIndex - 1;
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
}