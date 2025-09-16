import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rhythm_voice.dart';

// Simple enum for voice shapes since we're using string-based shapes in RhythmVoice
enum VoiceShape {
  circle,
  square,
  triangle,
  hexagon,
}

extension VoiceShapeExtension on VoiceShape {
  String get name {
    switch (this) {
      case VoiceShape.circle:
        return 'circle';
      case VoiceShape.square:
        return 'square';
      case VoiceShape.triangle:
        return 'triangle';
      case VoiceShape.hexagon:
        return 'hexagon';
    }
  }
}

class PolyrhythmPreset {
  final String id;
  final String name;
  final double bpm;
  final List<RhythmVoice> voices;
  final double masterVolume;
  final bool metronomeEnabled;
  final DateTime createdAt;

  PolyrhythmPreset({
    required this.id,
    required this.name,
    required this.bpm,
    required this.voices,
    required this.masterVolume,
    required this.metronomeEnabled,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bpm': bpm,
      'voices': voices.map((v) => v.toJson()).toList(),
      'masterVolume': masterVolume,
      'metronomeEnabled': metronomeEnabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PolyrhythmPreset.fromJson(Map<String, dynamic> json) {
    return PolyrhythmPreset(
      id: json['id'],
      name: json['name'],
      bpm: json['bpm'].toDouble(),
      voices: (json['voices'] as List)
          .map((v) => RhythmVoice.fromJson(v))
          .toList(),
      masterVolume: json['masterVolume'].toDouble(),
      metronomeEnabled: json['metronomeEnabled'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  PolyrhythmPreset copyWith({
    String? id,
    String? name,
    double? bpm,
    List<RhythmVoice>? voices,
    double? masterVolume,
    bool? metronomeEnabled,
    DateTime? createdAt,
  }) {
    return PolyrhythmPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
      voices: voices ?? this.voices,
      masterVolume: masterVolume ?? this.masterVolume,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PresetService {
  static const String _presetsKey = 'polyrhythm_presets';
  static const String _lastPresetKey = 'last_preset_id';
  
  SharedPreferences? _prefs;
  final List<PolyrhythmPreset> _presets = [];
  
  // Built-in presets
  static final List<PolyrhythmPreset> _builtInPresets = [
    PolyrhythmPreset(
      id: 'builtin_classic_34',
      name: 'Classic 3:4',
      bpm: 120,
      voices: [
        RhythmVoice(
          id: 'voice_3',
          numerator: 3,
          denominator: 4,
          color: Colors.red,
          volume: 0.8,
          shapeName: VoiceShape.circle.name,
        ),
        RhythmVoice(
          id: 'voice_4',
          numerator: 4,
          denominator: 4,
          color: Colors.blue,
          volume: 0.8,
          shapeName: VoiceShape.square.name,
        ),
      ],
      masterVolume: 0.8,
      metronomeEnabled: false,
      createdAt: DateTime.now(),
    ),
    PolyrhythmPreset(
      id: 'builtin_complex_57',
      name: 'Complex 5:7',
      bpm: 100,
      voices: [
        RhythmVoice(
          id: 'voice_5',
          numerator: 5,
          denominator: 8,
          color: Colors.green,
          volume: 0.7,
          shapeName: VoiceShape.triangle.name,
        ),
        RhythmVoice(
          id: 'voice_7',
          numerator: 7,
          denominator: 8,
          color: Colors.orange,
          volume: 0.7,
          shapeName: VoiceShape.hexagon.name,
        ),
      ],
      masterVolume: 0.8,
      metronomeEnabled: true,
      createdAt: DateTime.now(),
    ),
    PolyrhythmPreset(
      id: 'builtin_triplet_dance',
      name: 'Triplet Dance',
      bpm: 140,
      voices: [
        RhythmVoice(
          id: 'voice_3a',
          numerator: 3,
          denominator: 4,
          color: Colors.purple,
          volume: 0.9,
          shapeName: VoiceShape.circle.name,
        ),
        RhythmVoice(
          id: 'voice_4a',
          numerator: 4,
          denominator: 4,
          color: Colors.cyan,
          volume: 0.8,
          shapeName: VoiceShape.square.name,
        ),
        RhythmVoice(
          id: 'voice_6',
          numerator: 6,
          denominator: 4,
          color: Colors.yellow,
          volume: 0.6,
          shapeName: VoiceShape.triangle.name,
        ),
      ],
      masterVolume: 0.9,
      metronomeEnabled: false,
      createdAt: DateTime.now(),
    ),
    PolyrhythmPreset(
      id: 'builtin_african_rhythm',
      name: 'African Rhythm',
      bpm: 110,
      voices: [
        RhythmVoice(
          id: 'voice_2',
          numerator: 2,
          denominator: 3,
          color: Colors.brown,
          volume: 0.8,
          shapeName: VoiceShape.circle.name,
        ),
        RhythmVoice(
          id: 'voice_3b',
          numerator: 3,
          denominator: 4,
          color: Colors.deepOrange,
          volume: 0.7,
          shapeName: VoiceShape.triangle.name,
        ),
        RhythmVoice(
          id: 'voice_4b',
          numerator: 4,
          denominator: 3,
          color: Colors.teal,
          volume: 0.6,
          shapeName: VoiceShape.hexagon.name,
        ),
      ],
      masterVolume: 0.8,
      metronomeEnabled: true,
      createdAt: DateTime.now(),
    ),
  ];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPresets();
  }

  Future<void> _loadPresets() async {
    if (_prefs == null) return;
    
    _presets.clear();
    
    // Add built-in presets
    _presets.addAll(_builtInPresets);
    
    // Load user presets
    final presetsJson = _prefs!.getString(_presetsKey);
    if (presetsJson != null) {
      try {
        final List<dynamic> presetsList = jsonDecode(presetsJson);
        final userPresets = presetsList
            .map((json) => PolyrhythmPreset.fromJson(json))
            .toList();
        _presets.addAll(userPresets);
      } catch (e) {
        print('Error loading presets: $e');
      }
    }
  }

  Future<void> _saveUserPresets() async {
    if (_prefs == null) return;
    
    // Only save user presets (not built-in ones)
    final userPresets = _presets
        .where((preset) => !preset.id.startsWith('builtin_'))
        .toList();
    
    final presetsJson = jsonEncode(
      userPresets.map((preset) => preset.toJson()).toList(),
    );
    
    await _prefs!.setString(_presetsKey, presetsJson);
  }

  List<PolyrhythmPreset> get presets => List.unmodifiable(_presets);
  
  List<PolyrhythmPreset> get builtInPresets => 
      _presets.where((p) => p.id.startsWith('builtin_')).toList();
  
  List<PolyrhythmPreset> get userPresets => 
      _presets.where((p) => !p.id.startsWith('builtin_')).toList();

  Future<String> savePreset({
    required String name,
    required double bpm,
    required List<RhythmVoice> voices,
    required double masterVolume,
    required bool metronomeEnabled,
  }) async {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final preset = PolyrhythmPreset(
      id: id,
      name: name,
      bpm: bpm,
      voices: voices.map((v) => v.copyWith()).toList(), // Deep copy
      masterVolume: masterVolume,
      metronomeEnabled: metronomeEnabled,
      createdAt: DateTime.now(),
    );

    _presets.add(preset);
    await _saveUserPresets();
    return id;
  }

  Future<void> deletePreset(String id) async {
    // Don't allow deletion of built-in presets
    if (id.startsWith('builtin_')) return;
    
    _presets.removeWhere((preset) => preset.id == id);
    await _saveUserPresets();
  }

  Future<void> updatePreset(PolyrhythmPreset preset) async {
    // Don't allow updating built-in presets
    if (preset.id.startsWith('builtin_')) return;
    
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _presets[index] = preset;
      await _saveUserPresets();
    }
  }

  PolyrhythmPreset? getPreset(String id) {
    try {
      return _presets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastUsedPreset(String? presetId) async {
    if (_prefs == null) return;
    
    if (presetId != null) {
      await _prefs!.setString(_lastPresetKey, presetId);
    } else {
      await _prefs!.remove(_lastPresetKey);
    }
  }

  String? getLastUsedPresetId() {
    return _prefs?.getString(_lastPresetKey);
  }

  PolyrhythmPreset? getLastUsedPreset() {
    final id = getLastUsedPresetId();
    return id != null ? getPreset(id) : null;
  }

  // Generate a random preset
  PolyrhythmPreset generateRandomPreset() {
    final random = Random();
    final voiceCount = 2 + random.nextInt(3); // 2-4 voices
    final bpm = 80.0 + random.nextDouble() * 80; // 80-160 BPM
    
    final voices = <RhythmVoice>[];
    final usedRatios = <String>{};
    
    for (int i = 0; i < voiceCount; i++) {
      int numerator, denominator;
      String ratio;
      
      // Ensure unique ratios
      do {
        numerator = 2 + random.nextInt(6); // 2-7
        denominator = 3 + random.nextInt(5); // 3-7
        ratio = '$numerator:$denominator';
      } while (usedRatios.contains(ratio));
      
      usedRatios.add(ratio);
      
      final voice = RhythmVoice(
        id: 'random_voice_$i',
        numerator: numerator,
        denominator: denominator,
        color: _generateRandomColor(),
        volume: 0.6 + random.nextDouble() * 0.3, // 0.6-0.9
        shapeName: VoiceShape.values[random.nextInt(VoiceShape.values.length)].name,
      );
      
      voices.add(voice);
    }
    
    return PolyrhythmPreset(
      id: 'random_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Random ${_generateRandomName()}',
      bpm: bpm,
      voices: voices,
      masterVolume: 0.7 + random.nextDouble() * 0.2, // 0.7-0.9
      metronomeEnabled: random.nextBool(),
      createdAt: DateTime.now(),
    );
  }

  Color _generateRandomColor() {
    final random = Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.yellow,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
    ];
    return colors[random.nextInt(colors.length)];
  }

  String _generateRandomName() {
    final random = Random();
    final adjectives = [
      'Cosmic', 'Mystic', 'Electric', 'Flowing', 'Dancing',
      'Pulsing', 'Vibrant', 'Ethereal', 'Dynamic', 'Rhythmic',
      'Harmonic', 'Syncopated', 'Melodic', 'Groovy', 'Funky',
    ];
    final nouns = [
      'Waves', 'Pulse', 'Beat', 'Flow', 'Dance',
      'Rhythm', 'Pattern', 'Cycle', 'Loop', 'Groove',
      'Harmony', 'Melody', 'Tempo', 'Cadence', 'Motion',
    ];
    
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    return '$adjective $noun';
  }

  // Export preset as shareable text
  String exportPreset(PolyrhythmPreset preset) {
    final data = preset.toJson();
    final encoded = base64Encode(utf8.encode(jsonEncode(data)));
    return 'polyrhythm://$encoded';
  }

  // Import preset from shareable text
  PolyrhythmPreset? importPreset(String shareText) {
    try {
      if (!shareText.startsWith('polyrhythm://')) {
        return null;
      }
      
      final encoded = shareText.substring('polyrhythm://'.length);
      final decoded = utf8.decode(base64Decode(encoded));
      final json = jsonDecode(decoded);
      
      // Generate new ID for imported preset
      json['id'] = 'imported_${DateTime.now().millisecondsSinceEpoch}';
      json['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      
      return PolyrhythmPreset.fromJson(json);
    } catch (e) {
      print('Error importing preset: $e');
      return null;
    }
  }
}