import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'rhythm_voice.dart';

class PolyrhythmEngine extends ChangeNotifier {
  // Core timing
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  
  // Engine state
  bool _isPlaying = false;
  double _bpm = 120.0;
  double _masterVolume = 0.8;
  bool _metronomeEnabled = true;
  bool _visualOnlyMode = false;
  
  // Voices
  final List<RhythmVoice> _voices = [];
  
  // Callbacks for audio and visual updates
  Function(RhythmVoice voice, double time)? onVoiceBeat;
  Function(double time)? onMetronomeBeat;
  Function(double time)? onVisualUpdate;
  
  // Look-ahead scheduling
  static const double _lookAheadTime = 0.1; // 100ms look-ahead
  static const double _scheduleInterval = 0.025; // Check every 25ms
  double _nextScheduleTime = 0.0;
  
  // Metronome timing
  double _lastMetronomeTime = 0.0;
  
  PolyrhythmEngine() {
    _initializeDefaultVoices();
  }
  
  // Getters
  bool get isPlaying => _isPlaying;
  double get bpm => _bpm;
  double get masterVolume => _masterVolume;
  bool get metronomeEnabled => _metronomeEnabled;
  bool get visualOnlyMode => _visualOnlyMode;
  List<RhythmVoice> get voices => List.unmodifiable(_voices);
  double get currentTime => _stopwatch.elapsedMilliseconds / 1000.0;
  
  void _initializeDefaultVoices() {
    addVoice(3, 4, Colors.red);
    addVoice(4, 4, Colors.blue);
  }
  
  void play() {
    if (_isPlaying) return;
    
    _isPlaying = true;
    _stopwatch.start();
    _nextScheduleTime = currentTime;
    
    // Start the scheduling timer
    _ticker = Timer.periodic(
      Duration(milliseconds: (_scheduleInterval * 1000).round()),
      _onTick,
    );
    
    notifyListeners();
  }
  
  void pause() {
    if (!_isPlaying) return;
    
    _isPlaying = false;
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    
    notifyListeners();
  }
  
  void stop() {
    pause();
    _stopwatch.reset();
    _nextScheduleTime = 0.0;
    _lastMetronomeTime = 0.0;
    
    // Reset all voices
    for (final voice in _voices) {
      voice.reset();
    }
    
    notifyListeners();
  }
  
  void _onTick(Timer timer) {
    if (!_isPlaying) return;
    
    final now = currentTime;
    
    // Schedule events within the look-ahead window
    while (_nextScheduleTime < now + _lookAheadTime) {
      _scheduleEventsAt(_nextScheduleTime);
      _nextScheduleTime += _scheduleInterval;
    }
    
    // Always update visuals in real-time
    onVisualUpdate?.call(now);
  }
  
  void _scheduleEventsAt(double time) {
    // Schedule metronome beats
    if (_metronomeEnabled && !_visualOnlyMode) {
      final metronomeInterval = 60.0 / _bpm; // Quarter note interval
      if (time - _lastMetronomeTime >= metronomeInterval) {
        _lastMetronomeTime = time;
        onMetronomeBeat?.call(time);
      }
    }
    
    // Schedule voice beats
    if (!_visualOnlyMode) {
      for (final voice in _voices) {
        if (!voice.isMuted && _shouldVoicePlay(voice)) {
          if (voice.shouldTriggerBeat(time, _bpm)) {
            onVoiceBeat?.call(voice, time);
          }
        }
      }
    }
  }
  
  bool _shouldVoicePlay(RhythmVoice voice) {
    // If any voice is soloed, only play soloed voices
    final hasSoloedVoices = _voices.any((v) => v.isSolo);
    if (hasSoloedVoices) {
      return voice.isSolo;
    }
    return !voice.isMuted;
  }
  
  // Voice management
  void addVoice(int numerator, int denominator, Color color) {
    final id = 'voice_${DateTime.now().millisecondsSinceEpoch}';
    final voice = RhythmVoice(
      id: id,
      numerator: numerator,
      denominator: denominator,
      color: color,
      shapeName: _getRandomShape(),
    );
    _voices.add(voice);
    notifyListeners();
  }
  
  void removeVoice(String id) {
    _voices.removeWhere((voice) => voice.id == id);
    notifyListeners();
  }
  
  void updateVoice(String id, RhythmVoice updatedVoice) {
    final index = _voices.indexWhere((voice) => voice.id == id);
    if (index != -1) {
      _voices[index] = updatedVoice;
      notifyListeners();
    }
  }
  
  void toggleVoiceMute(String id) {
    final voice = _voices.firstWhere((v) => v.id == id);
    updateVoice(id, voice.copyWith(isMuted: !voice.isMuted));
  }
  
  void toggleVoiceSolo(String id) {
    final voice = _voices.firstWhere((v) => v.id == id);
    updateVoice(id, voice.copyWith(isSolo: !voice.isSolo));
  }
  
  // Settings
  void setBpm(double newBpm) {
    _bpm = newBpm.clamp(60.0, 200.0);
    notifyListeners();
  }
  
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void toggleMetronome() {
    _metronomeEnabled = !_metronomeEnabled;
    notifyListeners();
  }
  
  void toggleVisualOnlyMode() {
    _visualOnlyMode = !_visualOnlyMode;
    notifyListeners();
  }
  
  // Utility methods
  String _getRandomShape() {
    final shapes = ['circle', 'square', 'triangle', 'diamond', 'star'];
    return shapes[Random().nextInt(shapes.length)];
  }
  
  void randomizeVoices() {
    final random = Random();
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.cyan, Colors.pink, Colors.yellow
    ];
    
    for (int i = 0; i < _voices.length; i++) {
      final voice = _voices[i];
      final newColor = colors[random.nextInt(colors.length)];
      final newShape = _getRandomShape();
      
      _voices[i] = voice.copyWith(
        color: newColor,
        shapeName: newShape,
      );
    }
    notifyListeners();
  }
  
  // Preset management
  Map<String, dynamic> exportPreset() {
    return {
      'bpm': _bpm,
      'masterVolume': _masterVolume,
      'metronomeEnabled': _metronomeEnabled,
      'voices': _voices.map((v) => v.toMap()).toList(),
    };
  }
  
  void importPreset(Map<String, dynamic> preset) {
    stop();
    
    _bpm = preset['bpm'] ?? 120.0;
    _masterVolume = preset['masterVolume'] ?? 0.8;
    _metronomeEnabled = preset['metronomeEnabled'] ?? true;
    
    _voices.clear();
    if (preset['voices'] != null) {
      for (final voiceMap in preset['voices']) {
        _voices.add(RhythmVoice.fromMap(voiceMap));
      }
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}