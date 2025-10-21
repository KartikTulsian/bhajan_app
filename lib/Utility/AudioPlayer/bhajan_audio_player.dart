import 'package:audioplayers/audioplayers.dart';
import 'package:bhajan_app/main.dart';
import 'package:flutter/material.dart';
import 'package:bhajan_app/Model/bhajan_audio_player_model.dart';

class BhajanAudioPlayer extends StatefulWidget {
  const BhajanAudioPlayer({super.key});

  @override
  _BhajanAudioPlayerState createState() => _BhajanAudioPlayerState();
}

class _BhajanAudioPlayerState extends State<BhajanAudioPlayer> {
  AudioPlayer audioPlayer = playerData.player;
  //bool isPlaying = false;
  double audioDuration = 0.0;
  double currentDuration = 0.0;

  String totalDisplayDuration = "00:00";
  String currentDisplayDuration = "00:00";
  //String bhajanName = ' ';
  //String link = '';

  AudioPlayerData data = playerData;

  @override
  void initState() {
    super.initState();

    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        audioDuration = duration.inMilliseconds.toDouble();
        totalDisplayDuration = formatDurationInMmSs(duration);
      });
    });

    audioPlayer.onPositionChanged.listen((Duration duration) {
      setState(() {
        currentDuration = duration.inMilliseconds.toDouble();
        currentDisplayDuration = formatDurationInMmSs(duration);
      });
    });

    // Listen to player state changes
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        data.isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    // Don't dispose the shared player
    super.dispose();
  }

  // @override
  // void dispose() {
  //   audioPlayer.release();
  //   audioPlayer.dispose();
  //   super.dispose();
  // }

  void _pauseMusic() async {
    await audioHandler.pause();
    setState(() {
      data.isPlaying = false;
    });
  }

  void _resumeMusic() async {
    await audioHandler.play();
    setState(() {
      data.isPlaying = true;
    });
  }

  // void _seekBy(int seconds) {
  //   int currentPosition = currentDuration.toInt();
  //   int newPosition = currentPosition + (seconds * 1000);
  //
  //   if (newPosition < 0) {
  //     newPosition = 0;
  //   } else if (newPosition > audioDuration) {
  //     newPosition = audioDuration.toInt();
  //   }
  //
  //   setState(() {
  //     currentDuration = newPosition.toDouble();
  //   });
  //
  //   audioHandler.seek(Duration(milliseconds: newPosition));
  // }

  void _seekBy(int seconds) async { // Make it async
    // Delegate to the AudioHandler's methods (which implement 10s seek)
    if (seconds > 0) {
      await audioHandler.fastForward();
    } else if (seconds < 0) {
      await audioHandler.rewind();
    }

    // NOTE: Remove all local state updates for currentDuration here.
    // The AudioPlayer's onPositionChanged listener will update currentDuration,
    // keeping the UI automatically synchronized with the audioHandler.
  }

  String formatDurationInMmSs(Duration duration) {
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6.0, right: 6.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(84, 227, 202, 182),
        borderRadius: BorderRadius.circular(20), // Rounded edges
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 6.0, bottom: 6.0), // Specify the desired top margin
                child: SizedBox(
                  height: 24.0, // Specify the desired width
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      data.bhajanName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Color.fromARGB(255, 116, 93, 76),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.0, // Adjust thickness here
                        activeTrackColor: Colors.brown.shade500,
                        inactiveTrackColor: Colors.brown.shade200,
                        thumbColor: Colors.brown.shade500,
                        overlayColor: Colors.brown.withOpacity(0.2),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.0, // Adjust thumb size if needed
                        ),
                      ),
                      // Specify the desired height
                      child: Slider(
                        value: currentDuration,
                        min: 0.0,
                        max: audioDuration,
                        activeColor: Colors.brown.shade500,
                        inactiveColor: Colors.brown.shade200,
                        thumbColor: Colors.brown.shade500,
                        onChanged: (double value) {
                          setState(() {
                            currentDuration = value;
                          });
                          audioPlayer.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                ),
              ]),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 20),
                  child: Text(
                      currentDisplayDuration,
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.replay_10,
                      color: Color.fromARGB(255, 116, 93, 76)),
                  onPressed: () {
                    _seekBy(-10);
                  },
                  iconSize: 38,
                ),
                IconButton(
                  icon: data.isPlaying
                      ? const Icon(
                    Icons.pause,
                    color: Color.fromARGB(255, 116, 93, 76),
                  )
                      : const Icon(Icons.play_arrow,
                      color: Color.fromARGB(255, 116, 93, 76)),
                  onPressed: () {
                    if (data.isPlaying) {
                      _pauseMusic();
                    } else {
                      _resumeMusic();
                    }
                  },
                  iconSize: 38,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10,
                      color: Color.fromARGB(255, 116, 93, 76)),
                  onPressed: () {
                    _seekBy(10);
                  },
                  iconSize: 38,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 20),
                  child: Text(totalDisplayDuration,
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                ),
              ]),
        ],
      ),
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   audioPlayer.onDurationChanged.listen((Duration duration) {
  //     setState(() {
  //       audioDuration = duration.inMilliseconds.toDouble();
  //       totalDisplayDuration =
  //           formatDurationInMmSs(duration); //duration.inMinutes.toDouble();
  //     });
  //   });
  //
  //   audioPlayer.onPositionChanged.listen((Duration duration) {
  //     setState(() {
  //       currentDuration = duration.inMilliseconds.toDouble();
  //       currentDisplayDuration = formatDurationInMmSs(duration);
  //     });
  //   });
  // }
  //
  // void _pauseMusic() {
  //   audioPlayer.pause();
  //   setState(() {
  //     data.isPlaying = false;
  //   });
  // }
  //
  // void _resumeMusic() {
  //   audioPlayer.resume();
  //   setState(() {
  //     data.isPlaying = true;
  //   });
  // }
  //
  // void _seekBy(int seconds) {
  //   int currentPosition = currentDuration.toInt();
  //   int newPosition = currentPosition + (seconds * 1000);
  //
  //   if (newPosition < 0) {
  //     newPosition = 0;
  //   } else if (newPosition > audioDuration) {
  //     newPosition = audioDuration.toInt();
  //   }
  //
  //   setState(() {
  //     currentDuration = newPosition.toDouble();
  //   });
  //
  //   audioPlayer.seek(Duration(milliseconds: newPosition));
  // }

  void _playMusic(int listViewIndex, String url, int iconIndex) async {
    await audioPlayer.stop();
    await audioPlayer.release();
    late Source audioUrl;
    audioUrl = UrlSource(url);
    print('Playing bhajan index: $listViewIndex and icon: $iconIndex');
    print('Playing bhajan with URL: $url');
    await audioPlayer.play(audioUrl);

    //audioPlayer.onPlayerComplete.listen((event) {
    //playNextSong(listViewIndex, iconIndex);
    //});
    setState(() {
      data.isPlaying = true;
    });
    print('bhajan played');
  }

  // String formatDurationInMmSs(Duration duration) {
  //   final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
  //   final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
  //   return '$mm:$ss';
  // }
}
