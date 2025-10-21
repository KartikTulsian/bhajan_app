import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bhajan_app/Model/bhajan_audio_player_model.dart';

class BhajanAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = playerData.player;

  // Callbacks for navigation
  Function()? onSkipToNext;
  Function()? onSkipToPrevious;

  BhajanAudioHandler() {
    _init();
  }

  void _init() {
    // Initialize playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        // MediaControl(
        //   androidIcon: 'drawable/ic_replay_10',
        //   label: 'Rewind 10s',
        //   action: MediaAction.rewind,
        // ),
        MediaControl.rewind,
        MediaControl.play,
        MediaControl.pause,
        // MediaControl(
        //   androidIcon: 'drawable/ic_forward_10',
        //   label: 'Forward 10s',
        //   action: MediaAction.fastForward,
        // ),
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.rewind,
        MediaAction.fastForward,
      },
      androidCompactActionIndices: const [1, 3, 4],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));

    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;

      AudioProcessingState processingState;
      if (isPlaying) {
        // Use 'ready' when playing to enable progress bar in notification
        processingState = AudioProcessingState.ready;
      } else if (state == PlayerState.paused) {
        processingState = AudioProcessingState.ready;
      } else if (state == PlayerState.completed) {
        processingState = AudioProcessingState.completed;
      } else {
        processingState = AudioProcessingState.idle;
      }

      playerData.isPlaying = isPlaying;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          // MediaControl(
          //   androidIcon: 'drawable/ic_replay_10',
          //   label: 'Rewind 10s',
          //   action: MediaAction.rewind,
          // ),
          MediaControl.rewind,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          // MediaControl(
          //   androidIcon: 'drawable/ic_forward_10',
          //   label: 'Forward 10s',
          //   action: MediaAction.fastForward,
          // ),
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        // systemActions: {
        //   MediaAction.seek,
        //   MediaAction.seekForward,
        //   MediaAction.seekBackward,
        //   MediaAction.rewind,
        //   MediaAction.fastForward,
        // },
        // androidCompactActionIndices: const [0, 2, 4],
        // playing: isPlaying,
        // processingState: isPlaying
        //     ? AudioProcessingState.ready
        //     : AudioProcessingState.idle,

        playing: isPlaying,
        processingState: processingState,
      ));
    });

    // Update position
    _player.onPositionChanged.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Update duration
    _player.onDurationChanged.listen((duration) {
      if (mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // Handle completion
    _player.onPlayerComplete.listen((_) {
      if (onSkipToNext != null) {
        onSkipToNext!();
      }
    });
  }

  void setMediaItem(String title, String artist, String url) async {

    final Duration? currentDuration = await _player.getDuration();

    mediaItem.add(MediaItem(
      id: url,
      title: title,
      artist: artist,
      duration: currentDuration ?? Duration.zero,
      // artUri: null,
      album: 'Sadhna Path',
      extras: const {
        'android_icon_uri': 'resource://drawable/ic_notification'
      },
    ));

    _player.onDurationChanged.listen((duration) {
      if (mediaItem.value != null && mediaItem.value?.duration != duration) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> play() async {
    // await _player.resume();
    // playerData.isPlaying = true;

    // If mediaItem is null, the handler cannot play anything.
    if (mediaItem.value == null) return;

    // The logic to play/load the audio MUST be outside of the handler's play()
    // method if you are using an external widget (_playMusic in BhajanView)
    // to call audioPlayer.play(UrlSource(url)). The handler's play() should only
    // resume the player. Since BhajanView handles the initial play, this is fine.
    await _player.resume();

  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // playerData.isPlaying = false;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // playerData.isPlaying = false;

    // Clear notification when stopped
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) {
      onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) {
      onSkipToPrevious!();
    }
  }

  @override
  Future<void> fastForward() async {
    // FIX: Use getCurrentPosition() which is Future<Duration?>
    final currentPosition = await _player.getCurrentPosition();
    if (currentPosition == null) return;

    final newPosition = currentPosition.inMilliseconds + 10000;

    // Clamp to duration if available
    final duration = await _player.getDuration();
    final clampedPosition = newPosition.clamp(0, duration?.inMilliseconds ?? newPosition);

    await seek(Duration(milliseconds: clampedPosition));
  }

  @override
  Future<void> rewind() async {
    // FIX: Use getCurrentPosition() which is Future<Duration?>
    final currentPosition = await _player.getCurrentPosition();
    if (currentPosition == null) return;

    final newPosition = currentPosition.inMilliseconds - 10000;

    // Clamp the position to a minimum of zero
    await seek(Duration(milliseconds: newPosition.clamp(0, currentPosition.inMilliseconds)));
  }
}