import 'package:flutter/material.dart';

/// [ThemeToggleSwitch] mockup'taki "Tema Geçişi" bileşenidir: güneş ↔ ay
/// arasında kayan başparmaklı, gün batımı / gece gradyanlı anahtar.
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key, required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: isDark,
      label: 'Karanlık tema',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!isDark),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          width: 64,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? const [Color(0xFF1E3A8A), Color(0xFF312E81)]
                  : const [Color(0xFFFDE68A), Color(0xFFFDBA74)],
            ),
            border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.white),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plandaki soluk karşı ikon
              Align(
                alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOutBack,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFFE0E7FF) : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: _duration,
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.6, end: 1).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      key: ValueKey<bool>(isDark),
                      size: 16,
                      color: isDark ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
