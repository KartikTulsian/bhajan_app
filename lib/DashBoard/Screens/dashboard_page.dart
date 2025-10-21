import 'package:bhajan_app/DashBoard/Screens/auth/logout_page.dart';
import 'package:bhajan_app/DashBoard/Screens/bhajan_page.dart';
import 'package:bhajan_app/DashBoard/Screens/lyrisc_page.dart';
import 'package:bhajan_app/DashBoard/Screens/profile_page.dart';
import 'package:bhajan_app/Utility/AudioPlayer/bhajan_audio_player.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  int index = 0;
  // final screens = [
  //   ProfilePage(),
  //   const BhajanPage(),
  //   const LyriscPage(),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index < 3 ? index : 0, // Avoid error if logout is selected
        children: const [
          ProfilePage(),
          BhajanPage(),
          LyriscPage(),
        ],
      ),
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
                    onDestinationSelected: (int selectedIndex) {
                      if (selectedIndex == 3) {
                        // 👇 Show logout popup instead of switching tab
                        showLogoutPopup(context);
                      } else {
                        setState(() {
                          index = selectedIndex;
                        });
                      }
                    },
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
                        icon: Icon(Icons.logout, color: Colors.white),
                        label: 'Logout',
                      )
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void showLogoutPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Are you sure you want to logout?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white,),
                    label: const Text("Logout"),
                    onPressed: () {
                      Navigator.pop(context); // Close popup
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LogOutScreen()),
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFDEBFF),
                    ),
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context); // Just close popup
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
