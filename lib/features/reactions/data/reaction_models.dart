class ReactionOption {
  final String key;
  final String emoji;
  final String label;

  const ReactionOption({
    required this.key,
    required this.emoji,
    required this.label,
  });
}

const reactionOptions = [
  ReactionOption(key: 'like', emoji: '👍', label: 'Like'),
  ReactionOption(key: 'love', emoji: '❤️', label: 'Love'),
  ReactionOption(key: 'laugh', emoji: '😂', label: 'Laugh'),
  ReactionOption(key: 'wow', emoji: '😮', label: 'Wow'),
  ReactionOption(key: 'sad', emoji: '😢', label: 'Sad'),
  ReactionOption(key: 'angry', emoji: '😡', label: 'Angry'),
];

ReactionOption reactionOptionFor(String? key) {
  return reactionOptions.firstWhere(
    (option) => option.key == key,
    orElse: () => reactionOptions.first,
  );
}

class ReactionCount {
  final String reaction;
  final int count;

  const ReactionCount({required this.reaction, required this.count});

  factory ReactionCount.fromJson(Map<String, dynamic> json) => ReactionCount(
    reaction: json['reaction'] as String,
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

class ReactionPreview {
  final String userId;
  final String name;
  final String reaction;

  const ReactionPreview({
    required this.userId,
    required this.name,
    required this.reaction,
  });

  factory ReactionPreview.fromJson(Map<String, dynamic> json) =>
      ReactionPreview(
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Someone',
        reaction: json['reaction'] as String? ?? 'like',
      );
}

class ReactionSummary {
  final int total;
  final List<ReactionCount> counts;
  final List<ReactionPreview> preview;

  const ReactionSummary({
    required this.total,
    required this.counts,
    required this.preview,
  });

  static const empty = ReactionSummary(total: 0, counts: [], preview: []);

  factory ReactionSummary.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final json = raw.cast<String, dynamic>();
    return ReactionSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      counts: ((json['counts'] as List?) ?? const [])
          .map((e) => ReactionCount.fromJson((e as Map).cast<String, dynamic>()))
          .where((item) => item.count > 0)
          .toList(),
      preview: ((json['preview'] as List?) ?? const [])
          .map(
            (e) => ReactionPreview.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  ReactionSummary applyToggle({
    required String? previousReaction,
    required String reaction,
  }) {
    final nextReaction = previousReaction == reaction ? null : reaction;
    final countsByKey = {for (final item in counts) item.reaction: item.count};

    if (previousReaction != null) {
      countsByKey[previousReaction] = ((countsByKey[previousReaction] ?? 0) - 1)
          .clamp(0, 1 << 30);
    }
    if (nextReaction != null) {
      countsByKey[nextReaction] = (countsByKey[nextReaction] ?? 0) + 1;
    }

    final updatedCounts = reactionOptions
        .map(
          (option) => ReactionCount(
            reaction: option.key,
            count: countsByKey[option.key] ?? 0,
          ),
        )
        .where((item) => item.count > 0)
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final total = countsByKey.values.fold<int>(0, (sum, count) => sum + count);
    return ReactionSummary(total: total, counts: updatedCounts, preview: preview);
  }
}
