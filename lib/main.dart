import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/polyrhythm_engine.dart';
import 'models/rhythm_voice.dart';
import 'services/audio_service.dart';
import 'widgets/polyrhythm_canvas.dart';
import 'widgets/control_panel.dart';
import 'widgets/preset_panel.dart';
import 'services/preset_service.dart';

void main() {
  runApp(const PolyrhythmApp());
}

class PolyrhythmApp extends StatelessWidget {
  const PolyrhythmApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyrhythm Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PolyrhythmScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PolyrhythmScreen extends StatefulWidget {
  const PolyrhythmScreen({Key? key}) : super(key: key);

  @override
  State<PolyrhythmScreen> createState() => _PolyrhythmScreenState();
}

class _PolyrhythmScreenState extends State<PolyrhythmScreen> {
  late PolyrhythmEngine _engine;
  late AudioService _audioService;
  late PresetService _presetService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize engine
    _engine = PolyrhythmEngine();
    
    // Initialize audio service
    _audioService = AudioService();
    await _audioService.initialize();
    
    // Connect engine callbacks to audio service
    _engine.onVoiceBeat = (voice, time) {
      _audioService.scheduleVoiceBeat(voice, time);
    };
    
    _engine.onMetronomeBeat = (time) {
      _audioService.scheduleMetronomeBeat(time);
    };
    
    // Listen to engine changes for audio settings
    _engine.addListener(_onEngineChanged);
    
    setState(() {
      _isInitialized = true;
    });
  }

  void _onEngineChanged() {
    _audioService.setMasterVolume(_engine.masterVolume);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Initializing Polyrhythm Explorer...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ControlPanel(engine: _engine),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                     flex: 1,
                     child: PresetPanel(
                       engine: _engine,
                       presetService: _presetService,
                     ),
                   ),
                ],
              ),
            ),
            // Main canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PolyrhythmCanvas(
                     engine: _engine,
                     onVoiceTap: _handleVoiceTap,
                   ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleVoiceTap(RhythmVoice voice) {
    // Toggle solo/mute on tap
    if (voice.isSolo) {
      voice.isSolo = false;
    } else if (voice.isMuted) {
      voice.isMuted = false;
    } else {
      voice.isMuted = true;
    }
    setState(() {});
  }

  void _handleCanvasRotate(double delta) {
    // Rotate all voices
    for (final voice in _engine.voices) {
      voice.rotation += delta;
    }
    setState(() {});
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Polyrhythm Explorer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          // Info button
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
          
          // Settings button
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _onVoiceTap(RhythmVoice voice) {
    // Toggle mute on tap
    _engine.toggleVoiceMute(voice.id);
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Polyrhythm Explorer',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Polyrhythm Explorer!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'This app lets you explore complex polyrhythms through interactive visuals and synchronized audio.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              Text(
                'How to use:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '• Tap shapes to mute/unmute voices\n'
                '• Drag on canvas to rotate the view\n'
                '• Use controls to add voices and adjust settings\n'
                '• Try different rhythm ratios like 3:4, 5:7, etc.\n'
                '• Use the randomize button for inspiration!',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              Text(
                'Features:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '• Multiple rhythmic voices with custom ratios\n'
                '• Real-time visual transformations\n'
                '• Synchronized audio with low latency\n'
                '• Interactive 3D-style canvas\n'
                '• Metronome and visual-only modes',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.white),
              title: const Text(
                'Randomize Colors',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Give all voices new random colors',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                _engine.randomizeVoices();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.white),
              title: const Text(
                'Clear All Voices',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Remove all current voices',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                _showClearConfirmDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.white),
              title: const Text(
                'Reset to Default',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Reset to default 3:4 and 4:4 voices',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                _resetToDefault();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog() {
    Navigator.of(context).pop(); // Close settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear All Voices?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all current voices. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear all voices
              final voiceIds = _engine.voices.map((v) => v.id).toList();
              for (final id in voiceIds) {
                _engine.removeVoice(id);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    _engine.stop();
    
    // Clear all voices
    final voiceIds = _engine.voices.map((v) => v.id).toList();
    for (final id in voiceIds) {
      _engine.removeVoice(id);
    }
    
    // Add default voices
    _engine.addVoice(3, 4, Colors.red);
    _engine.addVoice(4, 4, Colors.blue);
    
    // Reset settings
    _engine.setBpm(120);
    _engine.setMasterVolume(0.8);
  }
}
