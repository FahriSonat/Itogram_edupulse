import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// [StudentQrPinScanner] öğrencinin canlı yoklamaya katıldığı paneldir:
/// **4 haneli PIN giriş kutusu** + **QR tarayıcı** düğmesi.
///
/// 4. hane girildiğinde kod otomatik doğrulanır ([onSubmitPin]). Süresi dolmuş
/// kod (Kural 1, `ExpiredQrPinException`) gibi hatalar kutuların altında
/// gösterilir; metin [errorMessageBuilder] ile özelleştirilebilir.
/// Kamera ile okutma [onOpenQrScanner] üzerinden açılır (tarayıcı paketi
/// sayfa / servis katmanında bağlanır).
class StudentQrPinScanner extends StatefulWidget {
  const StudentQrPinScanner({
    super.key,
    required this.onSubmitPin,
    required this.onOpenQrScanner,
    this.errorMessageBuilder,
  });

  static const int pinLength = 4;

  final Future<void> Function(String pin) onSubmitPin;
  final VoidCallback? onOpenQrScanner;
  final String Function(Object error)? errorMessageBuilder;

  @override
  State<StudentQrPinScanner> createState() => _StudentQrPinScannerState();
}

class _StudentQrPinScannerState extends State<StudentQrPinScanner> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _readable(Object e) {
    if (widget.errorMessageBuilder != null) return widget.errorMessageBuilder!(e);
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    final pin = _pinController.text.trim();
    if (pin.length != StudentQrPinScanner.pinLength) {
      setState(() => _errorText = AppStrings.pinCodeLengthError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await widget.onSubmitPin(pin);
      if (mounted) _pinController.clear();
    } catch (e) {
      if (mounted) setState(() => _errorText = _readable(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius20,
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: AppDimensions.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p10),
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yoklamaya Katıl',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        AppStrings.pinInputLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p20),
            _PinBoxes(
              controller: _pinController,
              focusNode: _focusNode,
              hasError: _errorText != null,
              enabled: !_isLoading,
              onChanged: (value) {
                if (_errorText != null) setState(() => _errorText = null);
                if (value.length == StudentQrPinScanner.pinLength) _handleSubmit();
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _errorText == null
                  ? const SizedBox(height: AppDimensions.p16)
                  : Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.p10, bottom: AppDimensions.p6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.criticalAbsenceRed),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                color: AppColors.criticalAbsenceRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const FittedBox(fit: BoxFit.scaleDown, child: Text('Kodu Doğrula')),
                  ),
                ),
                if (widget.onOpenQrScanner != null) ...[
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : widget.onOpenQrScanner,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('QR Okut')),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 4 ayrı hane kutusu; altında görünmez tek bir [TextField] klavye girişini alır.
class _PinBoxes extends StatelessWidget {
  const _PinBoxes({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Semantics(
      label: AppStrings.pinInputLabel,
      textField: true,
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final text = value.text;
                return Row(
                  children: [
                    for (var i = 0; i < StudentQrPinScanner.pinLength; i++) ...[
                      if (i > 0) const SizedBox(width: AppDimensions.p10),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                            borderRadius: AppDimensions.radius12,
                            border: Border.all(
                              color: hasError
                                  ? AppColors.criticalAbsenceRed
                                  : (focusNode.hasFocus && i == text.length.clamp(0, 3)
                                        ? primary
                                        : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                              width: focusNode.hasFocus && i == text.length.clamp(0, 3) ? 2 : 1.2,
                            ),
                          ),
                          child: Text(
                            i < text.length ? text[i] : '•',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: i < text.length
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            // Kutuların üzerinde, görünmez ama dokunulabilir giriş alanı.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: const ValueKey('pin_input_field'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: false,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: StudentQrPinScanner.pinLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(StudentQrPinScanner.pinLength),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
