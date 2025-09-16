import 'dart:ui';

class RhythmVoice {
  final String id;
  final int numerator;
  final int denominator;
  double volume;
  bool isMuted;
  bool isSolo;
  Color color;
  String shapeName;
  
  // Visual properties
  double scale;
  double rotation;
  double offsetX;
  double offsetY;
  
  // Internal timing
  double _lastBeatTime;
  int _beatCount;
  
  RhythmVoice({
    required this.id,
    required this.numerator,
    required this.denominator,
    this.volume = 0.7,
    this.isMuted = false,
    this.isSolo = false,
    required this.color,
    this.shapeName = 'circle',
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) : _lastBeatTime = 0.0, _beatCount = 0;
  
  /// Get the ratio as a decimal (numerator / denominator)
  double get ratio => numerator / denominator;
  
  /// Get the interval between beats in seconds for a given BPM
  double getBeatInterval(double bpm) {
    // Base beat interval (quarter note at given BPM)
    final baseBeatInterval = 60.0 / bpm;
    // Adjust for this voice's ratio
    return baseBeatInterval * (denominator / numerator);
  }
  
  /// Check if this voice should trigger a beat at the given time
  bool shouldTriggerBeat(double currentTime, double bpm) {
    final interval = getBeatInterval(bpm);
    
    if (currentTime - _lastBeatTime >= interval) {
      _lastBeatTime = currentTime;
      _beatCount++;
      return true;
    }
    return false;
  }
  
  /// Get the current phase (0.0 to 1.0) within the current beat cycle
  double getPhase(double currentTime, double bpm) {
    final interval = getBeatInterval(bpm);
    final timeSinceLastBeat = currentTime - _lastBeatTime;
    return (timeSinceLastBeat / interval).clamp(0.0, 1.0);
  }
  
  /// Reset timing state
  void reset() {
    _lastBeatTime = 0.0;
    _beatCount = 0;
  }
  
  /// Get beat count
  int get beatCount => _beatCount;
  
  /// Create a copy with modified properties
  RhythmVoice copyWith({
    String? id,
    int? numerator,
    int? denominator,
    double? volume,
    bool? isMuted,
    bool? isSolo,
    Color? color,
    String? shapeName,
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
  }) {
    return RhythmVoice(
      id: id ?? this.id,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      color: color ?? this.color,
      shapeName: shapeName ?? this.shapeName,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    ).._lastBeatTime = _lastBeatTime
     .._beatCount = _beatCount;
  }
  
  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numerator': numerator,
      'denominator': denominator,
      'volume': volume,
      'isMuted': isMuted,
      'isSolo': isSolo,
      'color': color.value,
      'shapeName': shapeName,
      'scale': scale,
      'rotation': rotation,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => toMap();

  /// Create from map for deserialization
  factory RhythmVoice.fromMap(Map<String, dynamic> map) {
    return RhythmVoice(
      id: map['id'],
      numerator: map['numerator'],
      denominator: map['denominator'],
      volume: map['volume'] ?? 0.7,
      isMuted: map['isMuted'] ?? false,
      isSolo: map['isSolo'] ?? false,
      color: Color(map['color']),
      shapeName: map['shapeName'] ?? 'circle',
      scale: map['scale'] ?? 1.0,
      rotation: map['rotation'] ?? 0.0,
      offsetX: map['offsetX'] ?? 0.0,
      offsetY: map['offsetY'] ?? 0.0,
    );
  }

  /// Create from JSON for deserialization
  factory RhythmVoice.fromJson(Map<String, dynamic> json) => RhythmVoice.fromMap(json);
}