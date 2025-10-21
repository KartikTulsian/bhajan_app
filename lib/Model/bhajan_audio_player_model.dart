import 'package:audioplayers/audioplayers.dart';
import 'package:bhajan_app/Model/list_item.dart';
import 'package:bhajan_app/Model/list_builder.dart';

class AudioPlayerData {
  static final AudioPlayerData _appData = AudioPlayerData._internal();

  bool isPlaying = false;
  String bhajanName = ' ';
  String link = '';
  List<Item> selectedList = hindi;
  int currentIndex = 0;

  AudioPlayer player = AudioPlayer();

  factory AudioPlayerData() {
    return _appData;
  }
  AudioPlayerData._internal();
}

final playerData = AudioPlayerData();