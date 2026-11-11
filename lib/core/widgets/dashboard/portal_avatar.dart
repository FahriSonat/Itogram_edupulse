import 'package:flutter/material.dart';

import '../../enums/user_role.dart';
import '../illustrations/character_avatar_painter.dart';

/// [PortalAvatar] hero alanındaki karakter rozeti.
///
/// Varsayılan olarak EduPulse'a özgü vektörel karakter çizilir
/// ([CharacterAvatarPainter]). [imageAsset] verilirse (ör. kullanıcının profil
/// fotoğrafı) o gösterilir; yüklenemezse yine karaktere düşer.
/// Halka rengi role göre değişir: Öğrenci mavi→turkuaz, Eğitmen indigo→mor.
class PortalAvatar extends StatelessWidget {
  const PortalAvatar({super.key, required this.role, this.size = 92, this.imageAsset});

  final UserRole role;
  final double size;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColors = switch (role) {
      UserRole.student => const [Color(0xFF3B82F6), Color(0xFF14B8A6)],
      UserRole.instructor => const [Color(0xFF6366F1), Color(0xFFA855F7)],
      UserRole.admin => const [Color(0xFF0284C7), Color(0xFF14B8A6)],
    };
    final innerColors = isDark
        ? const [Color(0xFF26355E), Color(0xFF16213F)]
        : const [Color(0xFFFFF3E6), Color(0xFFE6EEFF)];

    final character = CustomPaint(
      size: Size.square(size),
      painter: CharacterAvatarPainter(
        character: (role == UserRole.student) ? AvatarCharacter.student : AvatarCharacter.instructor,
      ),
    );

    final semanticLabel = switch (role) {
      UserRole.student => 'Öğrenci avatarı',
      UserRole.instructor => 'Eğitmen avatarı',
      UserRole.admin => 'Yönetici avatarı',
    };

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.04),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: ringColors),
          boxShadow: [
            BoxShadow(
              color: ringColors.last.withValues(alpha: isDark ? 0.45 : 0.3),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: innerColors),
          ),
          child: ClipOval(
            child: imageAsset == null
                ? character
                : Image.asset(imageAsset!, fit: BoxFit.cover, errorBuilder: (_, _, _) => character),
          ),
        ),
      ),
    );
  }
}
