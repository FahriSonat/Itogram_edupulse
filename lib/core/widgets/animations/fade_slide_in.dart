import 'package:flutter/material.dart';

/// [FadeSlideIn] çocuğunu ilk gösterimde gecikmeli olarak belirtip kaydırarak
/// (ve isteğe bağlı ölçekleyerek) ekrana getirir. Ana sayfa kartlarının sırayla
/// "akarak" gelmesi (stagger) için kullanılır.
///
/// - Gecikme, tek bir AnimationController içinde [Interval] ile uygulanır;
///   Timer kullanılmaz → dispose sonrası çalışma riski yoktur.
/// - Sistem "hareketi azalt" (Reduce Motion) açıksa animasyon atlanır.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 22),
    this.beginScale = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Başlangıçtaki kayma (piksel). Animasyon sonunda sıfırlanır.
  final Offset offset;

  /// Başlangıç ölçeği (ör. 0.85 → hafif "pop" efekti).
  final double beginScale;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayFraction, 1, curve: widget.curve),
  );
  bool _started = false;

  double get _delayFraction {
    final total = (widget.delay + widget.duration).inMicroseconds;
    return total == 0 ? 0 : widget.delay.inMicroseconds / total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (context, child) {
          final v = _t.value;
          final scale = widget.beginScale + (1 - widget.beginScale) * v;
          return Transform.translate(
            offset: widget.offset * (1 - v),
            child: scale == 1 ? child : Transform.scale(scale: scale, child: child),
          );
        },
      ),
    );
  }
}
