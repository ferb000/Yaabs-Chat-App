import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../media/audio/audio_player_controller.dart';

class AudioBubble extends ConsumerWidget {
  const AudioBubble({
    super.key,
    required this.url,
    required this.isMine,
    this.durationMs,
  });

  final String url;
  final bool isMine;
  final int? durationMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerControllerProvider);
    final controller = ref.read(audioPlayerControllerProvider.notifier);

    final isCurrent = audio.url == url;
    final playing = isCurrent && audio.playing;

    final duration = isCurrent
        ? audio.duration
        : (durationMs != null
              ? Duration(milliseconds: durationMs!)
              : Duration.zero);

    final position = isCurrent ? audio.position : Duration.zero;

    final max = duration.inMilliseconds == 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.blue.withOpacity(0.15)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.toggle(url),
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
          ),
          SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: value,
                  min: 0,
                  max: max,
                  onChanged: isCurrent
                      ? (v) =>
                            controller.seek(Duration(milliseconds: v.toInt()))
                      : null, // only seek when current
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position), style: const TextStyle(fontSize: 11)),
                    Text(_fmt(duration), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString();
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
