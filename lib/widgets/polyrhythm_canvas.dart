import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/rhythm_voice.dart';
import '../models/polyrhythm_engine.dart';

class PolyrhythmCanvas extends StatefulWidget {
  final PolyrhythmEngine engine;
  final Function(RhythmVoice)? onVoiceTap;
  
  const PolyrhythmCanvas({
    Key? key,
    required this.engine,
    this.onVoiceTap,
  }) : super(key: key);
  
  @override
  State<PolyrhythmCanvas> createState() => _PolyrhythmCanvasState();
}

class _PolyrhythmCanvasState extends State<PolyrhythmCanvas>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  double _canvasRotationX = 0.0;
  double _canvasRotationY = 0.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    // Set up visual update callback
    widget.engine.onVisualUpdate = (time) {
      if (mounted) {
        setState(() {});
      }
    };
    
    _animationController.repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanUpdate: _handlePanUpdate,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: CustomPaint(
             painter: PolyrhythmPainter(
               engine: widget.engine,
               canvasRotationX: _canvasRotationX,
               canvasRotationY: _canvasRotationY,
             ),
             size: Size.infinite,
           ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Check if tap is on any voice
    for (final voice in widget.engine.voices) {
      final voicePosition = _getVoicePosition(voice, center, size);
      final distance = (localPosition - voicePosition).distance;
      
      if (distance < 30) { // 30 pixel tap radius
        widget.onVoiceTap?.call(voice);
        break;
      }
    }
  }

  void _handlePanUpdate(PanUpdateDetails details) {
    setState(() {
      _canvasRotationX += details.delta.dy * 0.01;
      _canvasRotationY += details.delta.dx * 0.01;
      _canvasRotationX = _canvasRotationX.clamp(-0.5, 0.5);
      _canvasRotationY = _canvasRotationY.clamp(-0.5, 0.5);
    });
  }

  Offset _getVoicePosition(RhythmVoice voice, Offset center, Size size) {
    final radius = min(size.width, size.height) * 0.25;
    final index = widget.engine.voices.indexOf(voice);
    final angleStep = (2 * pi) / widget.engine.voices.length;
    final baseAngle = index * angleStep;
    final rotationSpeed = voice.ratio * 0.5;
    final currentAngle = baseAngle + (widget.engine.currentTime * rotationSpeed);
    
    return Offset(
      center.dx + cos(currentAngle) * radius + voice.offsetX,
      center.dy + sin(currentAngle) * radius + voice.offsetY,
    );
  }
}

class PolyrhythmPainter extends CustomPainter {
  final PolyrhythmEngine engine;
  final double canvasRotationX;
  final double canvasRotationY;
  final Function(RhythmVoice)? onVoiceTap;
  
  PolyrhythmPainter({
    required this.engine,
    required this.canvasRotationX,
    required this.canvasRotationY,
    this.onVoiceTap,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final currentTime = engine.currentTime;
    
    // Apply canvas rotation transform
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Apply 3D-ish rotation effect
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(canvasRotationX)
      ..rotateY(canvasRotationY);
    
    canvas.transform(transform.storage);
    canvas.translate(-center.dx, -center.dy);
    
    // Draw background grid
    _drawBackgroundGrid(canvas, size, currentTime);
    
    // Draw each voice
    for (int i = 0; i < engine.voices.length; i++) {
      final voice = engine.voices[i];
      _drawVoice(canvas, size, voice, i, currentTime);
    }
    
    // Draw center metronome indicator
    if (engine.metronomeEnabled) {
      _drawMetronome(canvas, size, currentTime);
    }
    
    canvas.restore();
  }
  
  void _drawBackgroundGrid(Canvas canvas, Size size, double currentTime) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;
    
    final gridSize = 50.0;
    final animOffset = (currentTime * 20) % gridSize;
    
    // Vertical lines
    for (double x = -animOffset; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = -animOffset; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  void _drawVoice(Canvas canvas, Size size, RhythmVoice voice, int index, double currentTime) {
    final center = Offset(size.width / 2, size.height / 2);
    final phase = voice.getPhase(currentTime, engine.bpm);
    
    // Calculate position in a circular arrangement
    final angleStep = (2 * pi) / engine.voices.length;
    final baseAngle = index * angleStep;
    final radius = min(size.width, size.height) * 0.25;
    
    // Add rotation based on voice phase
    final rotationSpeed = voice.ratio * 0.5;
    final currentAngle = baseAngle + (currentTime * rotationSpeed);
    
    final basePosition = Offset(
      center.dx + cos(currentAngle) * radius,
      center.dy + sin(currentAngle) * radius,
    );
    
    // Apply voice-specific transformations
    final position = Offset(
      basePosition.dx + voice.offsetX,
      basePosition.dy + voice.offsetY,
    );
    
    // Calculate scale with beat pulse effect
    final beatPulse = _getBeatPulse(voice, currentTime);
    final scale = voice.scale * (1.0 + beatPulse * 0.5);
    
    // Calculate color with beat flash effect
    final color = _getVoiceColor(voice, beatPulse);
    
    // Draw the shape
    _drawShape(canvas, voice.shapeName, position, scale * 30, color, voice.rotation + currentTime);
    
    // Draw voice info
    _drawVoiceInfo(canvas, voice, position, index);
  }
  
  double _getBeatPulse(RhythmVoice voice, double currentTime) {
    final phase = voice.getPhase(currentTime, engine.bpm);
    // Create a sharp pulse at the beginning of each beat
    return max(0.0, 1.0 - (phase * 4.0)).clamp(0.0, 1.0);
  }
  
  Color _getVoiceColor(RhythmVoice voice, double beatPulse) {
    if (voice.isMuted) {
      return voice.color.withOpacity(0.3);
    }
    
    if (voice.isSolo) {
      // Bright color for soloed voices
      return Color.lerp(voice.color, Colors.white, beatPulse * 0.5) ?? voice.color;
    }
    
    // Normal color with beat flash
    return Color.lerp(voice.color, Colors.white, beatPulse * 0.3) ?? voice.color;
  }
  
  void _drawShape(Canvas canvas, String shapeName, Offset position, double size, Color color, double rotation) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    switch (shapeName) {
      case 'circle':
        canvas.drawCircle(Offset.zero, size / 2, paint);
        canvas.drawCircle(Offset.zero, size / 2, strokePaint);
        break;
        
      case 'square':
        final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
        
      case 'triangle':
        _drawTriangle(canvas, size, paint, strokePaint);
        break;
        
      case 'diamond':
        _drawDiamond(canvas, size, paint, strokePaint);
        break;
        
      case 'star':
        _drawStar(canvas, size, paint, strokePaint);
        break;
    }
    
    canvas.restore();
  }
  
  void _drawTriangle(Canvas canvas, double size, Paint fillPaint, Paint strokePaint) {
    final path = Path();
    final radius = size / 2;
    
    path.moveTo(0, -radius);
    path.lineTo(-radius * 0.866, radius * 0.5);
    path.lineTo(radius * 0.866, radius * 0.5);
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
  
  void _drawDiamond(Canvas canvas, double size, Paint fillPaint, Paint strokePaint) {
    final path = Path();
    final radius = size / 2;
    
    path.moveTo(0, -radius);
    path.lineTo(radius, 0);
    path.lineTo(0, radius);
    path.lineTo(-radius, 0);
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
  
  void _drawStar(Canvas canvas, double size, Paint fillPaint, Paint strokePaint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = cos(angle - pi / 2) * radius;
      final y = sin(angle - pi / 2) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
  
  void _drawVoiceInfo(Canvas canvas, RhythmVoice voice, Offset position, int index) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${voice.numerator}:${voice.denominator}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + 40,
      ),
    );
  }
  
  void _drawMetronome(Canvas canvas, Size size, double currentTime) {
    final center = Offset(size.width / 2, size.height / 2);
    final metronomeInterval = 60.0 / engine.bpm;
    final phase = (currentTime % metronomeInterval) / metronomeInterval;
    
    // Draw metronome pulse
    final pulseIntensity = max(0.0, 1.0 - (phase * 3.0)).clamp(0.0, 1.0);
    
    if (pulseIntensity > 0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(pulseIntensity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawCircle(center, 20 + pulseIntensity * 10, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}