import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioPlayButton extends StatefulWidget {
  final String? usAudioFile;
  final double size;
  final Color? color;

  const AudioPlayButton({
    super.key,
    required this.usAudioFile,
    this.size = 44,
    this.color,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handlePlay() async {
    if (widget.usAudioFile == null || widget.usAudioFile!.isEmpty) return;

    setState(() => _isPlaying = true);
    _animController.forward(from: 0.0);

    await _audioService.playAudio(widget.usAudioFile);

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handlePlay,
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor.withOpacity(0.15),
            border: Border.all(color: buttonColor.withOpacity(0.4), width: 1.5),
          ),
          child: Icon(
            _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
            color: buttonColor,
            size: widget.size * 0.55,
          ),
        ),
      ),
    );
  }
}
