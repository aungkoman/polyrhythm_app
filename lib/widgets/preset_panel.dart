import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/polyrhythm_engine.dart';
import '../services/preset_service.dart';

class PresetPanel extends StatefulWidget {
  final PolyrhythmEngine engine;
  final PresetService presetService;

  const PresetPanel({
    Key? key,
    required this.engine,
    required this.presetService,
  }) : super(key: key);

  @override
  State<PresetPanel> createState() => _PresetPanelState();
}

class _PresetPanelState extends State<PresetPanel> {
  String? _selectedPresetId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPresetId = widget.presetService.getLastUsedPresetId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.library_music, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Presets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showRandomizeDialog,
                icon: const Icon(Icons.shuffle, color: Colors.white),
                tooltip: 'Generate Random Preset',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset list
          _buildPresetList(),
          
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    final presets = widget.presetService.presets;
    
    if (presets.isEmpty) {
      return const Center(
        child: Text(
          'No presets available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = preset.id == _selectedPresetId;
          final isBuiltIn = preset.id.startsWith('builtin_');

          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.3),
            leading: Icon(
              isBuiltIn ? Icons.star : Icons.music_note,
              color: isBuiltIn ? Colors.amber : Colors.white70,
            ),
            title: Text(
              preset.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${preset.voices.length} voices • ${preset.bpm.toInt()} BPM',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.white54,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isBuiltIn) ...[
                  IconButton(
                    onPressed: () => _sharePreset(preset),
                    icon: const Icon(Icons.share, size: 18),
                    color: Colors.white54,
                    tooltip: 'Share Preset',
                  ),
                  IconButton(
                    onPressed: () => _deletePreset(preset),
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red.withOpacity(0.7),
                    tooltip: 'Delete Preset',
                  ),
                ],
              ],
            ),
            onTap: () => _loadPreset(preset),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showSaveDialog,
            icon: const Icon(Icons.save),
            label: const Text('Save Current'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.file_download),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _loadPreset(PolyrhythmPreset preset) {
    setState(() {
      _selectedPresetId = preset.id;
    });

    // Stop current playback
    widget.engine.stop();

    // Clear current voices
    final currentVoiceIds = widget.engine.voices.map((v) => v.id).toList();
    for (final id in currentVoiceIds) {
      widget.engine.removeVoice(id);
    }

    // Load preset settings
    widget.engine.setBpm(preset.bpm);
    widget.engine.setMasterVolume(preset.masterVolume);
    if (preset.metronomeEnabled != widget.engine.metronomeEnabled) {
      widget.engine.toggleMetronome();
    }

    // Add preset voices
    for (final voice in preset.voices) {
      widget.engine.addVoice(voice.numerator, voice.denominator, voice.color);
      // Update the added voice with preset properties
      final addedVoice = widget.engine.voices.last;
      addedVoice.volume = voice.volume;
      addedVoice.isMuted = voice.isMuted;
      addedVoice.isSolo = voice.isSolo;
      addedVoice.shapeName = voice.shapeName;
    }

    // Save as last used preset
    widget.presetService.setLastUsedPreset(preset.id);

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded preset: ${preset.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSaveDialog() {
    _nameController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Save Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Current setup: ${widget.engine.voices.length} voices, ${widget.engine.bpm.toInt()} BPM',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveCurrentPreset,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveCurrentPreset() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a preset name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final presetId = await widget.presetService.savePreset(
        name: name,
        bpm: widget.engine.bpm,
        voices: widget.engine.voices,
        masterVolume: widget.engine.masterVolume,
        metronomeEnabled: widget.engine.metronomeEnabled,
      );

      setState(() {
        _selectedPresetId = presetId;
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "$name" saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportDialog() {
    _importController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Import Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _importController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Paste preset code here',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Paste a shared preset code starting with "polyrhythm://"',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _importPreset,
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _importPreset() async {
    final code = _importController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a preset code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final preset = widget.presetService.importPreset(code);
      if (preset == null) {
        throw Exception('Invalid preset code');
      }

      // Save the imported preset
      final presetId = await widget.presetService.savePreset(
        name: preset.name,
        bpm: preset.bpm,
        voices: preset.voices,
        masterVolume: preset.masterVolume,
        metronomeEnabled: preset.metronomeEnabled,
      );

      setState(() {
        _selectedPresetId = presetId;
      });

      Navigator.of(context).pop();

      // Load the imported preset
      _loadPreset(preset.copyWith(id: presetId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "${preset.name}" imported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing preset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sharePreset(PolyrhythmPreset preset) {
    final shareCode = widget.presetService.exportPreset(preset);
    
    Clipboard.setData(ClipboardData(text: shareCode));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "${preset.name}" copied to clipboard!'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Show Code',
          onPressed: () => _showShareDialog(preset, shareCode),
        ),
      ),
    );
  }

  void _showShareDialog(PolyrhythmPreset preset, String shareCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Share "${preset.name}"',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with others:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                shareCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareCode));
              Navigator.of(context).pop();
            },
            child: const Text('Copy Again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deletePreset(PolyrhythmPreset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${preset.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.presetService.deletePreset(preset.id);
              
              if (preset.id == _selectedPresetId) {
                setState(() {
                  _selectedPresetId = null;
                });
              }
              
              Navigator.of(context).pop();
              setState(() {}); // Refresh the list
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preset "${preset.name}" deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRandomizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Generate Random Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will create a random polyrhythm with 2-4 voices and random settings. Do you want to continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final randomPreset = widget.presetService.generateRandomPreset();
              Navigator.of(context).pop();
              _loadPreset(randomPreset);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}