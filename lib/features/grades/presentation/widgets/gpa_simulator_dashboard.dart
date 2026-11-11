import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [GpaSimulatorDashboard] öğrencinin **Dönem ağırlıklı ve Genel Not Ortalaması
/// (4.00)** gösterge panelidir. Genel GPA, Dönem GPA ve kazanılan kredi ile
/// 4.00 üzerinden dolum çubuğu gösterir; [onSimulateGpa] simülatörü açar.
class GpaSimulatorDashboard extends StatelessWidget {
  const GpaSimulatorDashboard({
    super.key,
    required this.cumulativeGpa,
    required this.termGpa,
    this.totalCredits = 0,
    this.onSimulateGpa,
  });

  static const double maxGpa = 4.0;

  final double cumulativeGpa; // 0.00 - 4.00
  final double termGpa;
  final int totalCredits;
  final VoidCallback? onSimulateGpa;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = (cumulativeGpa / maxGpa).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
        borderRadius: AppDimensions.radius20,
        border: isDark ? Border.all(color: AppColors.glowBlue.withValues(alpha: 0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primaryLight).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Akademik GPA & Başarı Paneli',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (onSimulateGpa != null) ...[
                const SizedBox(width: AppDimensions.p8),
                Semantics(
                  button: true,
                  label: 'GPA Simülatörünü aç',
                  child: InkWell(
                    onTap: onSimulateGpa,
                    borderRadius: AppDimensions.radiusFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppDimensions.radiusFull,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Simülatör',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.p20),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Genel GPA',
                    value: cumulativeGpa.toStringAsFixed(2),
                    sublabel: '4.00 Üzerinden',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.white24),
                Expanded(
                  child: _MetricItem(label: 'Dönem GPA', value: termGpa.toStringAsFixed(2), sublabel: 'Aktif Dönem'),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.white24),
                Expanded(
                  child: _MetricItem(label: 'Kredi / AKTS', value: '$totalCredits', sublabel: 'Kazanılan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),
          Semantics(
            label: 'Genel not ortalaması 4 üzerinden ${cumulativeGpa.toStringAsFixed(2)}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: AppDimensions.radiusFull,
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.00', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text('4.00', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value, required this.sublabel});

  final String label;
  final String value;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    // Dar ekran / büyük yazı ölçeğinde taşmak yerine küçülür.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(sublabel, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}
