import 'package:flutter/material.dart';
import '../models/polyrhythm_engine.dart';
import '../models/rhythm_voice.dart';

class ControlPanel extends StatefulWidget {
  final PolyrhythmEngine engine;
  
  const ControlPanel({
    Key? key,
    required this.engine,
  }) : super(key: key);
  
  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngineUpdate);
  }
  
  @override
  void dispose() {
    widget.engine.removeListener(_onEngineUpdate);
    super.dispose();
  }
  
  void _onEngineUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Main controls
          _buildMainControls(),
          const SizedBox(height: 20),
          
          // BPM and volume controls
          _buildSliderControls(),
          const SizedBox(height: 20),
          
          // Voice management
          _buildVoiceControls(),
          const SizedBox(height: 20),
          
          // Mode toggles
          _buildModeToggles(),
        ],
      ),
    );
  }
  
  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Play/Pause button
        ElevatedButton.icon(
          onPressed: () {
            if (widget.engine.isPlaying) {
              widget.engine.pause();
            } else {
              widget.engine.play();
            }
          },
          icon: Icon(
            widget.engine.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(widget.engine.isPlaying ? 'Pause' : 'Play'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.engine.isPlaying ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // Stop button
        ElevatedButton.icon(
          onPressed: widget.engine.stop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // Randomize button
        ElevatedButton.icon(
          onPressed: widget.engine.randomizeVoices,
          icon: const Icon(Icons.shuffle),
          label: const Text('Random'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSliderControls() {
    return Column(
      children: [
        // BPM Control
        Row(
          children: [
            const Icon(Icons.speed, color: Colors.white),
            const SizedBox(width: 10),
            const Text('BPM:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Slider(
                value: widget.engine.bpm,
                min: 60,
                max: 200,
                divisions: 140,
                label: '${widget.engine.bpm.round()}',
                onChanged: widget.engine.setBpm,
                activeColor: Colors.blue,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${widget.engine.bpm.round()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        // Master Volume Control
        Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Volume:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Slider(
                value: widget.engine.masterVolume,
                min: 0,
                max: 1,
                divisions: 100,
                label: '${(widget.engine.masterVolume * 100).round()}%',
                onChanged: widget.engine.setMasterVolume,
                activeColor: Colors.green,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${(widget.engine.masterVolume * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildVoiceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Voices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddVoiceDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Voice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Voice list
        if (widget.engine.voices.isEmpty)
          const Center(
            child: Text(
              'No voices added yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...widget.engine.voices.map((voice) => _buildVoiceItem(voice)).toList(),
      ],
    );
  }
  
  Widget _buildVoiceItem(RhythmVoice voice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: voice.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: voice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Voice ratio
          Text(
            '${voice.numerator}:${voice.denominator}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          
          // Shape indicator
          Text(
            voice.shapeName,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          
          const Spacer(),
          
          // Volume control
          SizedBox(
            width: 80,
            child: Slider(
              value: voice.volume,
              min: 0,
              max: 1,
              onChanged: (value) {
                widget.engine.updateVoice(
                  voice.id,
                  voice.copyWith(volume: value),
                );
              },
              activeColor: voice.color,
            ),
          ),
          
          // Mute button
          IconButton(
            onPressed: () => widget.engine.toggleVoiceMute(voice.id),
            icon: Icon(
              voice.isMuted ? Icons.volume_off : Icons.volume_up,
              color: voice.isMuted ? Colors.grey : Colors.white,
            ),
          ),
          
          // Solo button
          IconButton(
            onPressed: () => widget.engine.toggleVoiceSolo(voice.id),
            icon: Icon(
              Icons.headset,
              color: voice.isSolo ? Colors.yellow : Colors.grey,
            ),
          ),
          
          // Delete button
          IconButton(
            onPressed: () => widget.engine.removeVoice(voice.id),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeToggles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Metronome toggle
        ElevatedButton.icon(
          onPressed: widget.engine.toggleMetronome,
          icon: Icon(
            widget.engine.metronomeEnabled ? Icons.music_note : Icons.music_off,
          ),
          label: const Text('Metronome'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.engine.metronomeEnabled ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
        
        // Visual-only mode toggle
        ElevatedButton.icon(
          onPressed: widget.engine.toggleVisualOnlyMode,
          icon: Icon(
            widget.engine.visualOnlyMode ? Icons.visibility : Icons.volume_up,
          ),
          label: Text(widget.engine.visualOnlyMode ? 'Visual Only' : 'Audio + Visual'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.engine.visualOnlyMode ? Colors.orange : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  void _showAddVoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVoiceDialog(
        onAddVoice: (numerator, denominator, color) {
          widget.engine.addVoice(numerator, denominator, color);
        },
      ),
    );
  }
}

class AddVoiceDialog extends StatefulWidget {
  final Function(int numerator, int denominator, Color color) onAddVoice;
  
  const AddVoiceDialog({
    Key? key,
    required this.onAddVoice,
  }) : super(key: key);
  
  @override
  State<AddVoiceDialog> createState() => _AddVoiceDialogState();
}

class _AddVoiceDialogState extends State<AddVoiceDialog> {
  int _numerator = 3;
  int _denominator = 4;
  Color _selectedColor = Colors.red;
  
  final List<Color> _availableColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.cyan, Colors.pink, Colors.yellow,
    Colors.teal, Colors.indigo, Colors.lime, Colors.amber,
  ];
  
  final List<Map<String, int>> _commonRatios = [
    {'numerator': 3, 'denominator': 4},
    {'numerator': 4, 'denominator': 4},
    {'numerator': 5, 'denominator': 4},
    {'numerator': 7, 'denominator': 8},
    {'numerator': 3, 'denominator': 8},
    {'numerator': 5, 'denominator': 8},
  ];
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Add New Voice',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Common ratios
          const Text(
            'Common Ratios:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _commonRatios.map((ratio) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _numerator = ratio['numerator']!;
                    _denominator = ratio['denominator']!;
                  });
                },
                child: Text('${ratio['numerator']}:${ratio['denominator']}'),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          // Custom ratio inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Numerator',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null && num > 0) {
                      _numerator = num;
                    }
                  },
                  controller: TextEditingController(text: _numerator.toString()),
                ),
              ),
              const SizedBox(width: 10),
              const Text(':', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Denominator',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null && num > 0) {
                      _denominator = num;
                    }
                  },
                  controller: TextEditingController(text: _denominator.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Color picker
          const Text(
            'Color:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _availableColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAddVoice(_numerator, _denominator, _selectedColor);
            Navigator.of(context).pop();
          },
          child: const Text('Add Voice'),
        ),
      ],
    );
  }
}