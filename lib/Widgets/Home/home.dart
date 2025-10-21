import 'package:bhajan_app/Utility/AudioPlayer/bhajan_audio_player.dart';
import 'package:bhajan_app/Widgets/BhajanView/bhajan_view.dart';
import 'package:bhajan_app/Widgets/Home/mainpage.dart';
import 'package:bhajan_app/Widgets/KirtanBook/kirtanbook.dart';
import 'package:bhajan_app/Widgets/e-Books/ebook.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int index = 0;
  final screens = [
    Mainpage(),
    const BhajanView(),
    const LyricsView(),
    ebook(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: SafeArea(
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color.fromARGB(255, 116, 93, 76),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 10),
            ),
          ),
          child: SizedBox(
            height: 164,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const BhajanAudioPlayer(),
                Spacer(),
                NavigationBar(
                    height: 60,
                    backgroundColor: const Color.fromARGB(255, 227, 202, 182),
                    selectedIndex: index,
                    onDestinationSelected: (index) =>
                        setState(() => this.index = index),
                    destinations: const [
                      NavigationDestination(
                          icon: Icon(Icons.home_filled, color: Colors.white),
                          label: 'Home'),
                      NavigationDestination(
                          icon: Icon(Icons.music_note_rounded,
                              color: Colors.white),
                          label: 'Bhajans'),
                      NavigationDestination(
                        icon: Icon(Icons.lyrics_rounded, color: Colors.white),
                        label: 'Kirtan-Book',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined,
                            color: Colors.white),
                        label: 'e-Books',
                      ),
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
