import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../media/audio/audio_player_controller.dart';
import '../../../posts/utils/media_url.dart';

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
    final resolvedUrl = resolveMediaUrl(url);

    final isCurrent = audio.url == resolvedUrl;
    final playing = isCurrent && audio.playing;
    final hasError = isCurrent && audio.errorMessage != null;

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
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasError)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.toggle(resolvedUrl),
              icon: const Icon(Icons.refresh_rounded),
            )
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: audio.loading
                  ? null
                  : () => controller.toggle(resolvedUrl),
              icon: Icon(
                playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              ),
            ),
          SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      'Audio failed to load',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (audio.loading && isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                else
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
                    Text(
                      hasError ? 'Retry' : _fmt(position),
                      style: const TextStyle(fontSize: 11),
                    ),
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
