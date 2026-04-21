import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/podcast.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Podcast? _currentPodcast;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;

  AudioPlayer get audioPlayer => _audioPlayer;
  Podcast? get currentPodcast => _currentPodcast;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get progress => _duration.inSeconds > 0 
      ? _position.inSeconds / _duration.inSeconds 
      : 0.0;

  AudioProvider() {
    _init();
  }

  void _init() {
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  Future<void> playPodcast(Podcast podcast) async {
    if (_currentPodcast?.id == podcast.id) {
      await togglePlayPause();
      return;
    }

    try {
      _currentPodcast = podcast;
      _isLoading = true;
      notifyListeners();

      await _audioPlayer.setUrl(podcast.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing podcast: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    await seek(newPosition > _duration ? _duration : newPosition);
  }

  Future<void> skipBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPodcast = null;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
