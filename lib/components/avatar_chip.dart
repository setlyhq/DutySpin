import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/avatar.dart';

class AvatarChip extends StatelessWidget {
  const AvatarChip({super.key, required this.name, this.size = 44, this.imageUrl});

  final String name;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final bg = chipColor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
            )
          : Text(
              initials(name),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text),
            ),
    );
  }
}
