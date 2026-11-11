import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/animations/fade_slide_in.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../widgets/onboarding_illustrations.dart';

/// [IntroOnboardingPage] provides a rich, animated onboarding tour
/// introducing the 3 core pillars from the EduPulse mockup specification:
/// 1. Öğrenci & Eğitmen Çift Portal
/// 2. 60 Sn Canlı Yoklama Kalkanı (QR & PIN)
/// 3. Başarı Analitiği, Çan Eğrisi & GPA Simülatörü
class IntroOnboardingPage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const IntroOnboardingPage({super.key, required this.onGetStarted});

  @override
  State<IntroOnboardingPage> createState() => _IntroOnboardingPageState();
}

class _IntroOnboardingPageState extends State<IntroOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Görseller EduPulse'a özgü, kodla çizilmiş animasyonlu illüstrasyonlardır
  // (bkz. onboarding_illustrations.dart) — harici resim dosyası kullanılmaz.
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Öğrenci & Eğitmen Çift Portal',
      'subtitle': 'Tek uygulamada iki farklı dünya. Öğrenciler için ders, ödev ve not takibi; eğitmenler için tam yetkili akademik yönetim paneli.',
      'illustration': const DualPortalIllustration(),
      'icon': Icons.school_rounded,
      'badge': 'Çift Yönlü Rol Modeli',
      'color': AppColors.primaryLight,
    },
    {
      'title': '60 Sn Canlı Yoklama Kalkanı',
      'subtitle': 'Canlı derste her 60 saniyede bir otomatik yenilenen dinamik QR ve 4 haneli PIN ile sahte yoklamalara son veren güvenli yoklama sistemi.',
      'illustration': const QrCountdownIllustration(),
      'icon': Icons.qr_code_scanner_rounded,
      'badge': 'Kural 1: 60 Sn Güvenlik',
      'color': AppColors.accentDark,
    },
    {
      'title': 'Sınıf Çan Eğrisi & GPA Simülatörü',
      'subtitle': 'Material 3 CustomPainter ile çizilen Gaussian çan eğrisi grafiği, %20 devamsızlık kalkanı ve 4.00 baremli ağırlıklı not hesaplama motoru.',
      'illustration': const GradeCurveIllustration(),
      'icon': Icons.insights_rounded,
      'badge': 'Akademik Başarı Analitiği',
      'color': AppColors.secondaryLight,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const EduPulseLogo(size: 32, showText: true),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: widget.onGetStarted,
                      child: const Text('Atla', style: TextStyle(fontWeight: FontWeight.w600)),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final Color slideColor = slide['color'] as Color;

                  // Küçük ekran / büyük yazı ölçeğinde taşmasın diye kaydırılabilir;
                  // yer varsa içerik dikeyde ortalanır.
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Özgün illüstrasyon kartı
                            FadeSlideIn(
                              beginScale: 0.94,
                              child: Container(
                                height: (constraints.maxHeight * 0.48).clamp(170.0, 240.0),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF11182E) : Colors.white,
                                  borderRadius: AppDimensions.radius24,
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: slideColor.withValues(alpha: isDark ? 0.2 : 0.12),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(AppDimensions.p10),
                                child: ClipRRect(
                                  borderRadius: AppDimensions.radius16,
                                  child: slide['illustration'] as Widget,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.p24),

                            // Badge Pill
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 120),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: slideColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: AppDimensions.radiusFull,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(slide['icon'] as IconData, size: 14, color: slideColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      slide['badge'] as String,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: slideColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.p16),

                            FadeSlideIn(
                              delay: const Duration(milliseconds: 200),
                              child: Column(
                                children: [
                                  // Title
                                  Text(
                                    slide['title'] as String,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppDimensions.p10),

                                  // Subtitle
                                  Text(
                                    slide['subtitle'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      height: 1.45,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p24, vertical: AppDimensions.p20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSelected = _currentPage == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: AppDimensions.radiusFull,
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        widget.onGetStarted();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(120, AppDimensions.buttonHeightSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? 'Hemen Başla' : 'İleri',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
