import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/rhythm_voice.dart';

class AudioService {
  static const MethodChannel _channel = MethodChannel('audio_service');
  
  // Audio samples for different voice shapes
  final Map<String, String> _samplePaths = {
    'circle': 'assets/audio/kick.wav',
    'square': 'assets/audio/snare.wav', 
    'triangle': 'assets/audio/hihat.wav',
    'hexagon': 'assets/audio/cymbal.wav',
    'pentagon': 'assets/audio/tom.wav',
  };
  
  bool _isInitialized = false;
  double _masterVolume = 0.8;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize audio system
      await _channel.invokeMethod('initialize');
      _isInitialized = true;
      print('Audio service initialized');
    } catch (e) {
      print('Failed to initialize audio service: $e');
      // Fallback to synthesized audio
      _isInitialized = true;
    }
  }

  Future<void> _createSynthesizedTone(double frequency, double duration) async {
    // Synthesize tone using platform channel or fallback method
    try {
      await _channel.invokeMethod('playTone', {
        'frequency': frequency,
        'duration': duration,
        'volume': _masterVolume,
      });
    } catch (e) {
      // Fallback: use system beep or silent operation
      print('Synthesized tone playback failed: $e');
    }
  }

  void playVoiceBeat(RhythmVoice voice, double time) {
    if (!_isInitialized || voice.isMuted) return;
    
    // Calculate frequency based on voice ratio and shape
    final baseFrequency = _getVoiceFrequency(voice);
    final volume = voice.volume * _masterVolume;
    
    if (volume > 0.01) {
      _createSynthesizedTone(baseFrequency, 0.1);
    }
  }

  void playMetronomeBeat(double time) {
    if (!_isInitialized) return;
    
    // Play metronome click
    _createSynthesizedTone(800.0, 0.05);
  }

  double _getVoiceFrequency(RhythmVoice voice) {
    // Map voice shapes to different frequency ranges
    final shapeFrequencies = {
      'circle': 220.0,    // Low kick-like frequency
      'square': 440.0,    // Mid snare-like frequency  
      'triangle': 880.0,  // High hihat-like frequency
      'hexagon': 1320.0,  // Cymbal-like frequency
      'pentagon': 330.0,  // Tom-like frequency
    };
    
    final baseFreq = shapeFrequencies[voice.shapeName] ?? 440.0;
    
    // Modify frequency based on voice ratio for musical variation
    final ratioMultiplier = 1.0 + (voice.ratio - 1.0) * 0.2;
    return baseFreq * ratioMultiplier;
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  double get masterVolume => _masterVolume;

  void dispose() {
    // Clean up resources
    _isInitialized = false;
  }
}