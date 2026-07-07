import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../posts/utils/media_url.dart'
    show isVideoMediaUrl, resolveMediaUrl;

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 56,
    this.radius = 18,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final double radius;

  String _initial() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = avatarUrl == null || avatarUrl!.trim().isEmpty
        ? null
        : resolveMediaUrl(avatarUrl!.trim());
    final useImage = resolved != null && !isVideoMediaUrl(resolved);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: !useImage
          ? Center(
              child: Text(
                _initial(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.38,
                ),
              ),
            )
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _initial(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.38,
                  ),
                ),
              ),
            ),
    );
  }
}
