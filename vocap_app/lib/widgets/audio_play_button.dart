import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioPlayButton extends StatefulWidget {
  final String? usAudioFile;
  final String? audioFile;
  final double size;
  final Color? color;
  final String? label;

  const AudioPlayButton({
    super.key,
    this.usAudioFile,
    this.audioFile,
    this.size = 44,
    this.color,
    this.label,
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

  String? get _effectiveFile => widget.audioFile ?? widget.usAudioFile;

  Future<void> _handlePlay() async {
    final file = _effectiveFile;
    if (file == null || file.isEmpty) return;

    setState(() => _isPlaying = true);
    _animController.forward(from: 0.0);

    await _audioService.playAudio(file);

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;

    if (widget.label != null && widget.label!.isNotEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _effectiveFile != null && _effectiveFile!.isNotEmpty ? _handlePlay : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: buttonColor.withValues(alpha: 0.12),
              border: Border.all(color: buttonColor.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                  color: buttonColor,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _effectiveFile != null && _effectiveFile!.isNotEmpty ? _handlePlay : null,
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor.withValues(alpha: 0.15),
            border: Border.all(color: buttonColor.withValues(alpha: 0.4), width: 1.5),
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
